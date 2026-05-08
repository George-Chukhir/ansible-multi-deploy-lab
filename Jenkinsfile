pipeline{
    agent any
    tools{
        terraform 'terraform-1.14.9' //installed plugin and configured in Jenkins -> Tools
    }

    environment {
        DOCKER_COMPOSE_FILE = 'deploy_local/docker-compose.yml'
        ANSIBLE_INVENTORY_PATH = 'inventories/azure_rg/lab-dynamic-inventory.azure_rm.yaml'
        ANSIBLE_MASTER_PLAYBOOK = 'master_playbook.yml'
        // PROJECT_DIR = 'ansible_project' // deprecated



        RG_NAME = ''
        LB_PIP = ''
        DB_FQDN = ''
        VAULT_PASS_FILE = credentials('vault_pass') 


        VENV_DIR="/var/jenkins_home/ansible-venv"


    }


    parameters {
        booleanParam(name: 'run_terraform', defaultValue: true, description: 'Run Terraform to provision infrastructure')
        booleanParam(name: 'run_ansible_playbook', defaultValue: true, description: 'Run Ansible Playbook to configure the servers')
        booleanParam(name: 'destroy_infrastructure', defaultValue: false, description: 'Destroy infrastructure after deployment')
        
        // deprecated param
        // booleanParam(name: 'start_docker_containers', defaultValue: true, description: 'Start docker containers if they are not running')
    }

    options {
        timeout(time: 25, unit: 'MINUTES') 

        disableConcurrentBuilds()


        timestamps() 

    }




    stages{

        stage('PrepareVirtual Environment') {
            steps{
                sh '''
                    set -e

                    if [ ! -d "$VENV_DIR" ]; then
                        echo "Virtual environment not found. Creating..."

                        # call venv module to create virtual environment for ansible
                        python3 -m venv "$VENV_DIR"

                        # insgtall packages to venv
                        $VENV_DIR/bin/pip install --upgrade pip
                    fi

                    if [ -f "ansible/requirements.txt" ]; then
                        if [ -r "ansible/requirements.txt" ]; then
                            echo "Installing Ansible dependencies from requirements.txt..."
                            $VENV_DIR/bin/pip install -r ansible/requirements.txt  
                        else
                            echo "Error: requirements.txt is not readable. Please check file permissions." 
                            exit 1
                        fi
                    fi
                    if ! "$VENV_DIR/bin/ansible-galaxy" collection list | grep -q "azure.azcollection"; then
                        # instructions for proper work with API azure
                        echo "Virtual environment exists but Ansible Azure collection is not installed. Installing..."
                        $VENV_DIR/bin/ansible-galaxy collection install azure.azcollection
                        
                        #auto install all dependencies for azure collection
                        $VENV_DIR/bin/pip install -r /var/jenkins_home/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
                    else 
                        echo "Virtual environment and collection already exist. Skipping creation."
                    fi

                '''
            }
        }



        stage('Deploy IaC with Terraform') {
            when {
                expression { return params.run_terraform }
            }

            steps{

                dir('terraform'){
                    echo "Running Terraform to provision infrastructure..."
                    sh 'terraform init'
                    
                    withCredentials([
                                        string(credentialsId: 'id_rsa_pub', variable:'TF_VAR_ssh_rsa_public_key'), 
                                        usernamePassword(credentialsId: 'postgresql-admin-data', 
                                        usernameVariable: 'TF_VAR_db_admin_username', // TF_VAR_ will be ignored by terraform, asigned to variables.tf -> db_admin_username
                                        passwordVariable: 'TF_VAR_db_admin_password'), 
                                        ]) {
                        script {
                            retry(2) {
                                try {
                                    sh 'set -o pipefail; terraform apply -auto-approve 2>&1 | tee terraform_output.log'
                                }
                                catch (err) {
                                    echo "Error during Terraform deployment: ${err}"
                                    error("Terraform deployment failed. Aborting pipeline.")
                                }
                            }
                        }
                        echo "Terraform deployment completed successfully."
                    }
                }
            }

            post{
                always{
                    archiveArtifacts artifacts: 'terraform/terraform_output.log', allowEmptyArchive: true
                }
            }
        }


        // stage("Start containers if it's not running") {
        //     when {
        //         expression { return params.start_docker_containers }
        //     }

        //     steps{
        //         dir('deploy_local'){
        //             sh 'docker compose -p ${PROJECT_DIR} -f ${DOCKER_COMPOSE_FILE} up -d'
        //         }

        //     }
        // }


        stage('Parse outputs.tf'){
            steps{
                dir('terraform'){
                    script {
                        try {
                            env.RG_NAME = sh(script: 'terraform output -raw resource_group_name', returnStdout: true).trim()
                            env.LB_PIP = sh(script: 'terraform output -raw lb_public_ip', returnStdout: true).trim()
                            env.DB_FQDN = sh(script: 'terraform output -raw db_fqdn', returnStdout: true).trim()
                        }
                        catch (err) {
                            echo "Error retrieving Terraform output variables: ${err}"
                            error("Failed to retrieve vars from \"outputs.tf\" . Aborting pipeline.")
                        }
                    }
                }
                echo "Parsed successfully"
            }
        }
        
        // plugin for work with postgresql
        stage('Install community.postgresql'){
            steps{
                dir('ansible'){
                    sh 'ansible-galaxy collection install community.postgresql'
                }
            }
        }

    
        stage('Run Ansible Playbook') {
            when {
                expression { return params.run_ansible_playbook }
            }

            steps{      
                withCredentials([file(credentialsId: 'vault_pass', variable: 'VAULT_PASS_FILE'), 
                                 usernamePassword(credentialsId: 'postgresql-admin-data',
                                 usernameVariable: 'DB_ADMIN_USER',
                                 passwordVariable: 'DB_ADMIN_PASS') ]) {
                    dir('ansible'){
                    // set -o pipefail ensure that all tasks in pipe are executed successfully
                    // very very verbose
                        sh """
                            set -e;
                            set -o pipefail;

                            # protection from false positive results
                            export ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=True
                            export ANSIBLE_HOST_PATTERN_MISMATCH=error

                            export HOME="/var/jenkins_home"
                            export AZURE_CONFIG_DIR="/var/jenkins_home/.azure"

                            #show to system where to find AZURE CLI
                            export PATH="/var/jenkins_home/ansible-venv/bin:\$PATH"


                            echo "CHECKING AZURE CLI AUTHENTICATION..."
                            az account show || { echo "Keys not found or expired!"; exit 1; }
                            echo "=== KEYS FOUND, RUNNING ANSIBLE ==="

                            ${env.VENV_DIR}/bin/ansible-playbook -vvv -i ${ANSIBLE_INVENTORY_PATH} ${ANSIBLE_MASTER_PLAYBOOK} \
                            --vault-password-file \${VAULT_PASS_FILE} \
                            -e "postgresql_db_fqdn=${env.DB_FQDN}" \
                            -e "proxy_jump_host=${env.LB_PIP}" \
                             2>&1 | tee ansible_output.log 
                        """
                    }
                }
            }

            post{
                always {
                    archiveArtifacts artifacts: 'ansible/ansible_output.log', allowEmptyArchive: true
                }
            }
        } 

        stage ('Destroy Infrastructure') {
            when {
                expression { return params.destroy_infrastructure }
            }

            steps{
                dir('terraform') {
                    withCredentials([ 
                        usernamePassword(
                            credentialsId: 'postgresql-admin-data', 
                            usernameVariable: 'TF_VAR_db_admin_username', 
                            passwordVariable: 'TF_VAR_db_admin_password'
                        ),
                        string(credentialsId: 'id_rsa_pub', variable: 'TF_VAR_ssh_rsa_public_key')
                    ]) {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }



    post{
        always {
            deleteDir() // Clean up workspace after build
        }
        success {
            echo 'Pipeline finished successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
    
    }


}