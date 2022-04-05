node{

stage('checkout source') {
		try
		{
		   checkout scm
		}
stage('Authorize to Salesforce'){
	sfdx force:auth:jwt:grant --clientid 3MVG9pRzvMkjMb6lfpLf0bvNKCD1Cp1WhG2ldNQAYh6BlzmPLqR4.1uappghg9n1yM63qbzNRrsg9W.eHwpPE --jwtkeyfile server.key --username cva.bobbili@nagarro.com --instanceurl https://login.salesforce.com
     }
}