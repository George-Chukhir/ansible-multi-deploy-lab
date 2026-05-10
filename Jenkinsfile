pipeline{
    agent any
    tools{
        terraform 'terraform-1.14.9' //installed plugin and configured in Jenkins -> Tools
    }

    environment {
        DOCKER_COMPOSE_FILE = 'deploy_local/docker-compose.yml'
        
        ANSIBLE_INVENTORY_PATH = 'inventories/azure_rg/hosts.yml'
        ANSIBLE_MASTER_PLAYBOOK = 'master_playbook.yml'
        // PROJECT_DIR = 'ansible_project' // deprecated


        HOME = "/var/jenkins_home"
        AZURE_CONFIG_DIR = "/var/jenkins_home/.azure"

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
                    if [ -f "ansible/requirements.yml" ]; then
                            echo "Installing Ansible dependencies from requirements.yml..."
                            $VENV_DIR/bin/ansible-galaxy collection install -r ansible/requirements.yml
                    fi
                    echo "Virtual environment already exist. Skipping creation."
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


    
        stage('Run Ansible Playbook') {
            when {
                expression { return params.run_ansible_playbook }
            }

            steps{      
                withCredentials([file(credentialsId: 'vault_pass', variable: 'VAULT_PASS_FILE'), 
                                 usernamePassword(credentialsId: 'postgresql-admin-data',
                                 usernameVariable: 'DB_ADMIN_USER',
                                 passwordVariable: 'DB_ADMIN_PASS'),
                                 sshUserPrivateKey(credentialsId: 'id_rsa', keyFileVariable: 'SSH_KEY_FILE')
                                  ]) {
                    dir('ansible'){
                    // set -o pipefail ensure that all tasks in pipe are executed successfully
                    // very very verbose

                    // Way of ssh key: get from Jenkins storage -> put into tmp file -> via --key-file give a path to tmp file to ansible -> then delete tmp 
                        sh """
                            set -e;
                            set -o pipefail;

                            chmod 400 ${SSH_KEY_FILE}

                            #create local ssh agent to store ssh key for all ssh connections
                            eval \$(ssh-agent -s)
                            
                            ssh-add ${SSH_KEY_FILE}

                            export ANSIBLE_INVENTORY_ANY_UNPARSED_IS_FAILED=True
                            export ANSIBLE_HOST_PATTERN_MISMATCH=error

                            export PATH="/var/jenkins_home/ansible-venv/bin:\$PATH"

                            ${VENV_DIR}/bin/ansible-playbook -vvv -i ${ANSIBLE_INVENTORY_PATH} ${ANSIBLE_MASTER_PLAYBOOK} \
                            --private-key ${SSH_KEY_FILE} \
                            --vault-password-file \${VAULT_PASS_FILE} \
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