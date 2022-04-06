node{

stage('checkout source') {
		   checkout scm
		}

stage ('login'){
	sfdx auth:jwt:grant --clientid 3MVG9pRzvMkjMb6lfpLf0bvNKCD1Cp1WhG2ldNQAYh6BlzmPLqR4.1uappghg9n1yM63qbzNRrsg9W.eHwpPE \
--jwtkeyfile /Users/jdoe/JWT/server.key --username cva.bobbili@nagarro.com  \
--instanceurl https://login.salesforce.com
     }

}