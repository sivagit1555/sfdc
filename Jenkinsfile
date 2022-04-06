#!groovy

import groovy.json.JsonSlurperClassic

node {

    def SF_CONSUMER_KEY=env.SF_CONSUMER_KEY ?: "3MVG9pRzvMkjMb6lfpLf0bvNKCD1Cp1WhG2ldNQAYh6BlzmPLqR4.1uappghg9n1yM63qbzNRrsg9W.eHwpPE "
    def SF_USERNAME=env.SF_USERNAME ?: "bobbili.siva@nagarro.com"
    def SERVER_KEY_CREDENTALS_ID=env.SERVER_KEY_CREDENTALS_ID ?: "12345"
    def SF_INSTANCE_URL = env.SF_INSTANCE_URL ?: "https://login.salesforce.com"
    def DELTACHANGES = 'deltachanges'
	def DEPLOYDIR = 'toDeploy'
	def APIVERSION = '51.0'
    def toolbelt = tool 'toolbelt'
//	def scannerHome = tool 'SonarScanner'

stage('Clean Workspace') {
            deleteDir()
        }

stage('checkout source') {
		   checkout scm
		}

stage ('login'){
	 withEnv(["HOME=${env.WORKSPACE}"]) {
        
        withCredentials([file(credentialsId: SERVER_KEY_CREDENTALS_ID, variable: 'server_key_file')]) {

            // -------------------------------------------------------------------------
            // Authorize the Dev Hub org with JWT key and give it an alias.
            // -------------------------------------------------------------------------

            
                }
            }
     }

stage('Delta changes')
		{
			script
            {
                //bat "echo y | sfdx plugins:install sfpowerkit"
				
                rc = command "${toolbelt}/sfdx sfpowerkit:project:diff --revisionfrom %PreviousCommitId% --revisionto %LatestCommitId% --output ${DELTACHANGES} --apiversion ${APIVERSION} -x"
                if (rc != 0) 
				{
					currentBuild.result = "FAILED"
					emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
					error 'Unable to generate Delta changes.....'
				} 
				def folder = fileExists 'DeltaChanges/force-app'
				def file = fileExists 'DeltaChanges/destructiveChanges.xml'
    
				if( folder && !file )
				{
					dir("${WORKSPACE}/${DELTACHANGES}")
					{
						println "Force-app folder exist, destructiveChanges.xml doesn't exist"
						rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
					}
				} 
				else if ( !folder && file ) 
				{
					bat "copy manifest\\package.xml ${DELTACHANGES}"
					println "Force-app folder doesn't exist, destructiveChanges.xml exist" 
				}
				else if ( folder && file ) 
				{
					dir("${WORKSPACE}/${DELTACHANGES}")
					{
						println "Force-app folder exist, destructiveChanges.xml exist"
						if (DeploymentType=='Deploy Only')
						{
							println "You selected deploy only so deleting destructivechanges.xml to avoid component deletion."
							bat "del /f destructiveChanges.xml"
							rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
						}
						else if (DeploymentType=='Delete and Deploy')
						{
							println "Both deletion and deployment will be performed."
							rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
							bat "copy destructiveChanges.xml ..\\${DEPLOYDIR}"
						}
						else if (DeploymentType=='Delete Only')
						{
							println "You selected Delete only but force-app folder also exist. So deleting the force-app folder to avoid deployment."
							bat "echo y | rmdir /s force-app"
							bat "copy ..\\manifest\\package.xml ."
						}
						else if (DeploymentType=='Validate Only')
                        {
                            println "You selected Validate Only, so only validation will be performed."
                            rc = command "${toolbelt}/sfdx force:source:convert -d ../${DEPLOYDIR}"
                        }
					}
				}
				else 
				{
					currentBuild.result = "FAILED"
					emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
					error "There are no changes between the provided commit IDs that can be deployed or deleted."
				}
				
               
            }
        }



		stage('Validate Only') 
		{
			if (DeploymentType=='Validate only')
			{
				script
				{
				
					if (TESTLEVEL=='NoTestRun') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --checkonly --wait 10 --targetusername ${SF_USERNAME}" 
					}
					else if (TESTLEVEL=='RunLocalTests') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --checkonly --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} --verbose --loglevel trace"
					}
					else if (TESTLEVEL=='RunSpecifiedTests')
					{
						println TESTLEVEL
						def Testclass = SpecifyTestClass.replaceAll('\\s','')
						println Testclass
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --checkonly --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} -r ${Testclass} --verbose --loglevel debug"
					}
   
					if (rc != 0) 
					{
						currentBuild.result = "FAILED"
						emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
						error 'Metadata Validation Failed.'
					} 
				}
			}
   		}
		

   }