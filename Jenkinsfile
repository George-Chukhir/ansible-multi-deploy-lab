pipeline{
    agent any

    environment {
        ANSIBLE_INVENTORY_PATH = 'invetories/local_docker/hosts.yml'
        ANSIBLE_MASTER_PLAYBOOK = 'master_playbook.yml'
    }

    parameters {
        booleanParam(name: 'Start docker containers', defaultValue: true, description: 'Start docker containers if they are not running')
        booleanParam(name: 'Run Ansible Playbook', defaultValue: true, description: 'Run Ansible Playbook to configure the servers')
    }

    options {
        timeout(time: 5, unit: 'MINUTES') 

        disableConcurrentBuilds()



        timestamps() 

    }




    stages{


        stage('Start containers if it's not running') {
            when {
                expression { return params.Start_docker_containers }
            }

            steps{
                sh 'docker-compose up -d'
            }
        }
        
        stage('Run Ansible Playbook') {
            when {
                expression { return params.Run_Ansible_Playbook }
            }

            steps{
                sh "ansible-playbook -i ${ANSIBLE_INVENTORY_PATH} ${ANSIBLE_MASTER_PLAYBOOK} --vault-password-file vault.pass"
            }
        }

    }


}