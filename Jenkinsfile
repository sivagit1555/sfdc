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

	 withEnv(["HOME=${env.WORKSPACE}"]) {
        
        withCredentials([file(credentialsId: SERVER_KEY_CREDENTALS_ID, variable: 'server_key_file')]) {

            // -------------------------------------------------------------------------
            // Authorize the Dev Hub org with JWT key and give it an alias.
            // -------------------------------------------------------------------------

            stage('Authorize DevHub') {
                rc = command "${toolbelt}/sfdx auth:jwt:grant --instanceurl ${SF_INSTANCE_URL} --clientid ${SF_CONSUMER_KEY} --username ${SF_USERNAME} --jwtkeyfile ${server_key_file} --setdefaultdevhubusername --setalias HubOrg"
                if (rc != 0) {
                    error 'Salesforce dev hub org authorization failed.'
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