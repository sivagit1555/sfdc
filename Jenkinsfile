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
	
	//----------------------------------------------------------------------
	//Check if Previous and Latest commit IDs are provided.
	//----------------------------------------------------------------------
	
	try 
	{
		if ((params.PreviousCommitId != '') && (params.LatestCommitId != ''))
			println('')
		else throw new Exception()
			//error("Please enter both Previous and Latest commit IDs")
	} catch (Exception e) {
		currentBuild.result = "FAILED"
		println('Please enter both Previous and Latest commit IDs')
		emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
		throw e
	}
	

	//----------------------------------------------------------------------
	//Check if Previous and Latest commit IDs are same.
	//----------------------------------------------------------------------
	
	try
	{
		if (params.PreviousCommitId != params.LatestCommitId)
			println('')
		else throw new Exception()	
		//error("Previous and Latest Commit IDs can't be same.")
	} catch (Exception e) {
		currentBuild.result = "FAILED"
		println("Commit IDs can't be same. Please run the build again and enter 2 different commit IDs.")
		emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
		throw e
	}

	
	//----------------------------------------------------------------------
	//Check if Test classes are mentioned in case of RunSpecifiedTests.
	//----------------------------------------------------------------------
		
	if (TESTLEVEL=='RunSpecifiedTests')
	{
		try
		{
			if (params.SpecifyTestClass != '')
				println('')
			else throw new Exception()	
			//error("Please Specify Test classes.")
		}catch (Exception e) {
		currentBuild.result = "FAILED"
		println("Please specify test class name in the input box.")
		emailext (attachLog: true, body: '$PROJECT_NAME - Build # $BUILD_NUMBER - FAILED    $BUILD_URL', subject: '$DEFAULT_SUBJECT', to: '$DEFAULT_RECIPIENTS')
		throw e
		}
	}
	

    stage('Clean Workspace') {
        try {
            deleteDir()
        }
       
    }
    // -------------------------------------------------------------------------
    // Check out code from source control.
    // -------------------------------------------------------------------------

    stage('checkout source') {
		try
		{
		   checkout scm
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
			
		}


		stage('Delta changes')
		{
			script
            {
                //bat "echo y | sfdx plugins:install sfpowerkit"
				
                rc = command "${toolbelt}/sfdx sfpowerkit:project:diff --revisionfrom %PreviousCommitId% --revisionto %LatestCommitId% --output ${DELTACHANGES} --apiversion ${APIVERSION} -x"
                if (rc != 0) 
				
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

