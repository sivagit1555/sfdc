#!groovy

node {

    def SF_CONSUMER_KEY=env.SF_CONSUMER_KEY
    def SF_USERNAME=env.SF_USERNAME
    def SERVER_KEY_CREDENTIALS_ID=env.SERVER_KEY_CREDENTIALS_ID
    def SF_INSTANCE_URL = env.SF_INSTANCE_URL ?: "https://login.salesforce.com"
	def DELTACHANGES = 'deltachanges'
	def DEPLOYDIR = 'toDeploy'
	def APIVERSION = '51.0'
    def toolbelt = tool 'toolbelt'
//	def scannerHome = tool 'SonarScanner'
	
    stage('Clean Workspace') {
        try {
            deleteDir()
        }
        catch (Exception e) {
		currentBuild.result = "FAILED"
		println('Unable to Clean WorkSpace.')
		emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
		throw e       
        }
    }
    // -------------------------------------------------------------------------
    // Check out code from source control.
    // -------------------------------------------------------------------------

    stage('checkout source') {
		try
		{
		   checkout scm
		} catch (Exception e) {
		currentBuild.result = "FAILED"
		println('Error in checking out the code from Git repository.')
		emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
		throw e  
		}
	}

    // -------------------------------------------------------------------------
    // Run all the enclosed stages with access to the Salesforce
    // JWT key credentials.
    // -------------------------------------------------------------------------

 	withEnv(["HOME=${env.WORKSPACE}"]) {	
	
	    withCredentials([file(credentialsId: SERVER_KEY_CREDENTIALS_ID, variable: 'server_key_file')]) {
		// -------------------------------------------------------------------------
		// Authenticate to Salesforce using the server key.
		// -------------------------------------------------------------------------

		stage('Authorize to Salesforce') {
			
			rc = command "${toolbelt}/sfdx auth:jwt:grant --instanceurl ${SF_INSTANCE_URL} --clientid ${SF_CONSUMER_KEY} --jwtkeyfile ${server_key_file} --username ${SF_USERNAME} --setalias ${SF_USERNAME}"
		    if (rc != 0) 
			{
				currentBuild.result = "FAILED"
				emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
				error 'Salesforce org authorization failed.'
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
		

        // -------------------------------------------------------------------------
		// Deploy metadata and execute unit tests.
		// -------------------------------------------------------------------------
		

		stage('Deploy and Run Tests') 
		{
			if (DeploymentType=='Validate and Deploy')
			{	
				script
				{
					if (TESTLEVEL=='NoTestRun') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} "
					}
					else if (TESTLEVEL=='RunLocalTests') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} --verbose --loglevel debug"
					}
					else if (TESTLEVEL=='RunSpecifiedTests') 
					{
						println TESTLEVEL
						def Testclass = SpecifyTestClass.replaceAll('\\s','')
						println Testclass						
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} -r ${Testclass} --verbose --loglevel debug"
					}
					
					if (rc != 0) 
					{
						currentBuild.result = "FAILED"
						emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
						error 'Metadata  Failed.'
					} 

				}
			}
		}

		stage('Delete Components') 
		{
			if (DeploymentType=='Delete Components Only')
			{
				rc = command "${toolbelt}/sfdx force:mdapi:deploy -u ${SF_USERNAME} -d ${DELTACHANGES} -w 1"	
				if (rc != 0) 
					{
						currentBuild.result = "FAILED"
						emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
						error 'Component deletion failed.'
					} 
			}


		}

		stage('Delete, Validate and Deploy') 
		{
			if (DeploymentType=='Delete and Deploy')
			{
				script
				{
					if (TESTLEVEL=='NoTestRun') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} "
					}
					else if (TESTLEVEL=='RunLocalTests') 
					{
						println TESTLEVEL
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} --verbose --loglevel debug"
					}
					else if (TESTLEVEL=='RunSpecifiedTests') 
					{
						println TESTLEVEL
						def Testclass = SpecifyTestClass.replaceAll('\\s','')
						println Testclass						
						rc = command "${toolbelt}/sfdx force:mdapi:deploy -d ${DEPLOYDIR} --wait 10 --targetusername ${SF_USERNAME} --testlevel ${TESTLEVEL} -r ${Testclass} --verbose --loglevel debug"
					}
					if (rc != 0) 
					{
						currentBuild.result = "FAILED"
						emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
						error 'Metadata  Failed.'
					} 
				}
				
			}
		}
	
		stage('EMail Notification')
		{
			bat 'chdir'
			if (DeploymentType=='Delete Only')
			{
				dir("${WORKSPACE}/${DELTACHANGES}")
				{
				emailext attachmentsPattern: 'destructiveChanges.xml', attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:    $BUILD_URL', subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!', to: '$DEFAULT_RECIPIENTS, knkumarnikhil93@gmail.com'
				}
			}
			else if(DeploymentType=='Delete and Deploy')
			{
				dir("${WORKSPACE}/${DEPLOYDIR}")
				{
				bat 'chdir'
				emailext attachmentsPattern: 'package.xml, destructiveChanges.xml', attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:    $BUILD_URL', subject: '$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!', to: '$DEFAULT_RECIPIENTS, knkumarnikhil93@gmail.com'	
				}
			}
			else
			{
				dir("${WORKSPACE}/${DEPLOYDIR}")
				{
				bat 'chdir'
				emailext attachmentsPattern: 'package.xml', attachLog: true, body: '$DEFAULT_CONTENT', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS'
				}
			}
		}
	
	
		}
	}


}


	
def command(script) {
    if (isUnix()) {
        return sh(returnStatus: true, script: script);
    } else {
		return bat(returnStatus: true, script: script);
    }
}

