pipeline{
    agent any

    environment {
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
        ANSIBLE_INVENTORY_PATH = 'inventories/local_docker/hosts.yml'
        ANSIBLE_MASTER_PLAYBOOK = 'master_playbook.yml'
    }

    parameters {
        booleanParam(name: 'start_docker_containers', defaultValue: true, description: 'Start docker containers if they are not running')
        booleanParam(name: 'run_ansible_playbook', defaultValue: true, description: 'Run Ansible Playbook to configure the servers')
    }

    options {
        timeout(time: 5, unit: 'MINUTES') 

        disableConcurrentBuilds()


        timestamps() 

    }




    stages{

        stage('Init Pipeline') {
            steps{
                echo "Initializing pipeline with parameters:"

            }
        }


        stage("Start containers if it's not running") {
            when {
                expression { return params.start_docker_containers }
            }

            steps{
                sh 'docker compose -f ${DOCKER_COMPOSE_FILE} up -d'
            }
        }
        
        stage('Run Ansible Playbook') {
            when {
                expression { return params.run_ansible_playbook }
            }

            steps{
                sh "ansible-playbook -i ${ANSIBLE_INVENTORY_PATH} ${ANSIBLE_MASTER_PLAYBOOK} --vault-password-file vault.pass 2>&1 | tee ansible_output.log"
            }

            post{
                always {
                    archiveArtifacts artifacts: 'ansible_output.log', allowEmptyArchive: true
                }
            }
        }

    }


    post{
        success {
            echo 'Pipeline finished successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
    
    }


}