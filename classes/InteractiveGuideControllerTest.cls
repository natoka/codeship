/**************************************************************************************************
 * Name: InteractiveGuideControllerTest
 * Purpose: Test class for InteractiveGuideController
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-05
 * Modify History:
 * 2016-02-05    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
@isTest
private class InteractiveGuideControllerTest {

    static testMethod void testScheduledRecording_Runas () {

        // Creates XLC customer user
        User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

        // Creates account and update the Customer__c to the XLCCustomer user ID.
        Account acc = TestDataUtil.createAccount();
        acc.Customer__c = XLCCustomer.Id;
        update acc;

        // Shares the account with the XLC customer
        AccountShare accShare = new AccountShare(AccountId = acc.Id,
                                                 UserOrGroupId = XLCCustomer.Id,
                                                 AccountAccessLevel = 'Edit',
                                                 CaseAccessLevel = 'Edit',
                                                 OpportunityAccessLevel = 'Edit');
        insert accShare;

        // Creates the recording device then share with XLCCustomer user ID.
        Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
        insert recordingDevice;

        Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
                                                                  UserOrGroupId = XLCCustomer.Id,
                                                                  AccessLevel = 'Edit');
        insert rds;

        // Creats Show
        Show__c show = new Show__c(Name = 'Alaska Frontier');
        insert show;

        Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

        // Creates broadcasts
        List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
        Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
        broadcasts.add(b1);
        Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
        broadcasts.add(b2);
        Broadcast__c b3 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(2));
        broadcasts.add(b3);
        insert broadcasts;

        // Creates scheduled recordings, rec1 leave for test.
        List<Recording__c> recordings = new List<Recording__c> ();
        Recording__c rec2 = new Recording__c (Broadcast__c = b2.Id, Recording_Device__c = recordingDevice.ID);
        recordings.add(rec2);
        Recording__c rec3 = new Recording__c (Broadcast__c = b3.Id, Recording_Device__c = recordingDevice.ID);
        recordings.add(rec3);
        insert recordings;

        // Runs as XLC customer user
        System.runAs(XLCCustomer) {

            // Start Test
            Test.startTest();

            // Opens the InteractiveGuide page
            PageReference pr = new PageReference('/apex/InteractiveGuide');
            Test.setCurrentPage(pr);
            InteractiveGuideController con = new InteractiveGuideController ();
            System.assert(con.showBroadCastDetails == false);
            System.assert(con.hasMessages == false);
            System.assert(con.paginateNumber == 0);
            System.assertEquals(con.thisCustomer.Recording_Devices__r.size(), 1);
            System.assertEquals(con.channelList.size(), 7);            
            System.assertEquals(con.recordingDeviceOptions.size(), 1);

            // Sets selected recording device to test device ID.
            con.selectedRecordingDevice = recordingDevice.Id;

            // Shows the channel broadcasts
            con.populateChannelBroadcasts();
            System.assertEquals(con.broadcastMap.values().size(), 3);

            // Verifies click on the broadcast name show the broadcast details
            con.showBroadCastDetail();
            con.selectedBroadcastID = b1.Id;
            con.selectedBroadcast = b1;
            System.assert(con.isSubscribedChannels == false);

            // Next Page
            con.next();
            System.assert(con.hasMessages == false);
            System.assertEquals(con.paginateNumber, 1);

            // Previous Page
            con.previous();
            System.assert(con.hasMessages == false);
            System.assertEquals(con.paginateNumber, 0);

            // Verifies subscribe now button
            con.subscribeNow();
            System.assert(con.isSubscribedChannels);
            System.assertEquals([SELECT count() FROM Account WHERE Subscribed_Channels__c INCLUDES ('CNN')], 1);

            // Verifies record a broadcast
            con.record();
            List<Recording__c> newRecording = [SELECT Id
                                               FROM Recording__c
                                               WHERE Broadcast__c =: con.selectedBroadcast.Id
                                               AND Recording_Device__c =: con.selectedRecordingDevice];
            System.assertEquals(newRecording.size(), 1);
            System.assertEquals(con.showBroadCastDetails, false);
            System.assert(con.hasMessages == false);

            // Verifies cancel a broadcast
            con.cancelRecording();
            List<Recording__c> cancelRecording = [SELECT Id
                                                  FROM Recording__c
                                                  WHERE Broadcast__c =: con.selectedBroadcast.Id
                                                  AND Recording_Device__c =: con.selectedRecordingDevice];
            System.assertEquals(cancelRecording.size(), 1);
            System.assertEquals(con.showBroadCastDetails, false);
            System.assert(con.hasMessages == false);
            Test.stopTest();
        }
    }

    static testMethod void testNoRunas_Negative () {

        // Creates account and update the Customer__c to the XLCCustomer user ID.
        Account acc = TestDataUtil.createAccount();

        // Creates the recording device then share with XLCCustomer user ID.
        Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
        insert recordingDevice;

        // Creats Show
        Show__c show = new Show__c(Name = 'Alaska Frontier');
        insert show;

        Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

        // Creates broadcasts
        List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
        Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
        broadcasts.add(b1);
        Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
        broadcasts.add(b2);

        Broadcast__c b3 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(2));
        broadcasts.add(b3);
        insert broadcasts;

        // Creates scheduled recordings, rec1 leave for test.
        List<Recording__c> recordings = new List<Recording__c> ();
        Recording__c rec2 = new Recording__c (Broadcast__c = b2.Id, Recording_Device__c = recordingDevice.ID);
        recordings.add(rec2);
        Recording__c rec3 = new Recording__c (Broadcast__c = b3.Id, Recording_Device__c = recordingDevice.ID);
        recordings.add(rec3);
        insert recordings;

        // Start Test
        Test.startTest();

        // Opens the InteractiveGuide page
        PageReference pr = new PageReference('/apex/InteractiveGuide');
        Test.setCurrentPage(pr);
        InteractiveGuideController con = new InteractiveGuideController ();
        Boolean foundContactAdministrator = false;
        Boolean foundQueryException = false;
        for(ApexPages.Message msg : ApexPages.getMessages()) {
            if (msg.getSummary() == 'Cannot finds related account information for current User, please contact system administrator')  {
                foundContactAdministrator = true;
            }

            if (msg.getSummary() == 'List has no rows for assignment to SObject') {
                foundQueryException = true;
            }
        }

        System.assert(foundContactAdministrator);
        System.assert(foundQueryException);
        Test.stopTest();
    }

    static testMethod void testScheduledRecordingRecordAll_Runas () {

        // Creates XLC customer user
        User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

        // Creates account and update the Customer__c to the XLCCustomer user ID.
        Account acc = TestDataUtil.createAccount();
        acc.Customer__c = XLCCustomer.Id;
        update acc;

        // Shares the account with the XLC customer
        AccountShare accShare = new AccountShare(AccountId = acc.Id,
                                                 UserOrGroupId = XLCCustomer.Id,
                                                 AccountAccessLevel = 'Edit',
                                                 CaseAccessLevel = 'Edit',
                                                 OpportunityAccessLevel = 'Edit');
        insert accShare;

        // Creates the recording device then share with XLCCustomer user ID.
        Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
        insert recordingDevice;

        Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
                                                                  UserOrGroupId = XLCCustomer.Id,
                                                                  AccessLevel = 'Edit');
        insert rds;

        // Creats Show
        Show__c show = new Show__c(Name = 'Alaska Frontier');
        insert show;

        Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

        // Creates broadcasts
        List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
        Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
        broadcasts.add(b1);
        Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(2));
        broadcasts.add(b2);
        Broadcast__c b3 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(3));
        broadcasts.add(b3);
        insert broadcasts;

        // Runs as XLC customer user
        System.runAs(XLCCustomer) {

            // Start Test
            Test.startTest();

            // Opens the InteractiveGuide page
            PageReference pr = new PageReference('/apex/InteractiveGuide');
            Test.setCurrentPage(pr);
            InteractiveGuideController con = new InteractiveGuideController ();

            // Sets selected recording device to test device ID.
            con.selectedRecordingDevice = recordingDevice.Id;

            // Show the channel broadcasts
            con.populateChannelBroadcasts();
            System.assertEquals(con.broadcastMap.values().size(), 3);

            // Verifies click on the broadcast name show the broadcast details
            con.selectedBroadcastID = b1.Id;
            con.selectedBroadcast = b1;
            con.showBroadCastDetail();
 
            // Verifies record all broadcasts
            con.recordAll();
            List<Recording__c> newRecordAll = [SELECT Id
                                               FROM Recording__c
                                               WHERE Broadcast__r.Channel__c = 'Discovery'
                                               AND Recording_Device__c =: con.selectedRecordingDevice];
            System.assertEquals(newRecordAll.size(), 3);
            System.assertEquals(con.showBroadCastDetails, false);
            System.assert(con.hasMessages == false);

            Test.stopTest();
        }
    }
}