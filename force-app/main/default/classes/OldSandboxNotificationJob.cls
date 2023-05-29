global class OldSandboxNotificationJob implements Schedulable {
    private static final String LOG_LOCATION = 'OldSandboxNotificationJob';
    private static final String NOTIFICATION_SUBJECT = 'Old Sandbox notification';
    private static final String NOTIFICATION_RECIPIENT = UserInfo.getUserEmail();
    global void execute(SchedulableContext sc) {
        sendOldSandboxNotification();
    }

    private static void sendOldSandboxNotification() {
        String query = 'SELECT SandboxName, Description, LicenseType, LastModifiedById, LastModifiedDate From SandboxInfo WHERE LastModifiedDate < LAST_N_MONTHS:6 AND LicenseType != \'FULL\' ORDER BY LastModifiedDate';
        ToolingApiService.MetadataQueryStructure result = new ToolingApiService().getMetadataQuery(query);
        if (result.isSuccess && result.records != null && !result.records.isEmpty()) {
            Set<Id> userIds = new Set<Id>();
            Map<Id, List<ToolingApiService.SandboxInfoStructure>> userSandboxMap = new Map<Id, List<ToolingApiService.SandboxInfoStructure>>();
            for (Object o : result.records) {
                Map<String, Object> obj = (Map<String, Object>) o;
                ToolingApiService.SandboxInfoStructure sis = new ToolingApiService.SandboxInfoStructure(obj);
                userIds.add(sis.LastModifiedById);
                if (userSandboxMap.containsKey(sis.LastModifiedById)) {
                    userSandboxMap.get(sis.LastModifiedById).add(sis);
                } else {
                    userSandboxMap.put(sis.LastModifiedById, new List<ToolingApiService.SandboxInfoStructure>{ sis });
                }
            }
            Map<Id, User> users = new Map<Id, User> ([SELECT Id, Username FROM User WHERE Id IN :userIds]);
            String emailBody = 'Please review sandboxes of people who left and your own, if are still needed:\n';
            for (Id userId : userSandboxMap.keySet()) {
                emailBody += '\n' + users.get(userId).Username;
                for (ToolingApiService.SandboxInfoStructure sis : userSandboxMap.get(userId)) {
                    emailBody += '\n   - Name: ' + sis.SandboxName + '   Refresh date: ' + sis.LastModifiedDate + '   Description: ' + sis.Description + '\n';
                }
            }

            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setSubject(NOTIFICATION_SUBJECT);
            emailMessage.setPlainTextBody(emailBody);
            emailMessage.setToAddresses(new List<String>{ NOTIFICATION_RECIPIENT });
            emailMessage.setSaveAsActivity(false);
            try {
                List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{
                        emailMessage
                }, false);
                if (!emailResults.isEmpty() || !emailResults[0].isSuccess()) {
                    //Logger.log(Logger.Level.ERROR, 'Old Sandbox notification was not possible to send: ' + emailResults[0].getErrors(), LOG_LOCATION);
                }
            } catch (Exception e) {
                //Logger.log(Logger.Level.ERROR, 'There is an issue with old Sandbox notification: ' + e.getMessage(), LOG_LOCATION, e);
            }
        } else {
            //Logger.log(Logger.Level.ERROR, 'There is an issue with old Sandbox notification: ' + result.message, LOG_LOCATION);
        }
    }

    public static String start() {
        OldSandboxNotificationJob schedulable = new OldSandboxNotificationJob();
        String cron = '0 0 0 1 * ?';
        return System.schedule('OldSandboxNotificationJob', cron, schedulable);
    }
}