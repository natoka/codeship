/**************************************************************************************************
 * Name: InteractiveGuideController
 * Purpose: Controller for InteractiveGuide page
            1. Gets the recording devices of this customer as a picklist in the page.
            2. Gets the channel list from account Subscribed_Channels__c field then put as the first column
            3. Gets the broadcast list in the GMTtime list and the scheduled recordings in the selected device.
            4. Previous page of currently time slot
            5. Nexts page of currently time slot
            6. Shows the selected broad cast details
            7. Subscribes the selected broadcast channel
            8. Records the selected broadcast
            9. Records selected broadcast plus future broadcasts that exist.
            10. Cancels the recording for this particular broadcast.
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-04
 * Modify History:
 * 2016-02-04    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
public with sharing class InteractiveGuideController {

    static final Integer COLUMN_GRID = 6;
    public Account thisCustomer;
    public List<SelectOption> recordingDeviceOptions { get; set; }
    public List<String> channelList { get; set; }
    public Boolean hasMessages { get; set; }
    public Boolean isSubscribedChannels { get; set; }

    private DateTime userLocalStartTime;
    private List<DateTime> GMTTimeList;
    public List<DateTime> userLocalTimeList { get; set; }

    public String selectedRecordingDevice { get; set; }
    public Map<String, List<Broadcast__c>> channelBroadcastMap { get; set; }
    public Map<ID, Broadcast__c> broadcastMap;
    private Integer scheduleRecordingStatus;
    public Map<String, Integer> broadcastScheduleRecordingStatusMap { get; set; }

    public Broadcast__c selectedBroadcast { get; set; }
    public String selectedBroadcastID { get; set; }

    public Boolean showBroadCastDetails { get; set; }
    public Integer paginateNumber { get; set; }

    // Constructor for the class to initial the customer / recording devices information, channel list and time list
    public InteractiveGuideController () {

        // Sets the Broadcast page block hide by default
        showBroadCastDetails = false;
        hasMessages = false;
        paginateNumber = 0;

        // Gets the customer and recording devices
        recordingDeviceOptions = new List<SelectOption> ();
        try {

            thisCustomer = [SELECT Subscribed_Channels__c,
                                (SELECT Name
                                 FROM Recording_Devices__r
                                 ORDER BY Name ASC)
                            FROM Account
                            WHERE Customer__c =: UserInfo.getUserId()
                            LIMIT 1];
            System.debug(LoggingLevel.INFO, '*** thisCustomer: ' + thisCustomer);

            // Puts recording devices to picklist on page
            for (Recording_Device__c rd : thisCustomer.Recording_Devices__r) {
                recordingDeviceOptions.add(new SelectOption(rd.Id, rd.Name));
            }

            // Sets the default selected device
            selectedRecordingDevice = recordingDeviceOptions[0].getValue();
            System.debug(LoggingLevel.INFO, '*** recordingDeviceOptions: ' + recordingDeviceOptions);

        } catch (QueryException qe) {
            hasMessages = true;
            if (thisCustomer == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    'Cannot finds related account information for current User, please contact system administrator'));
            }
            ApexPages.addMessages(qe);
        }

        // Gets the channel list form Subscribed_Channels__c field on the account.
        channelList = new List<String> ();
        Schema.DescribeFieldResult subcribedChannels = Account.Subscribed_Channels__c.getDescribe();
        List<Schema.PicklistEntry> ple = subcribedChannels.getPicklistValues();

        for (Schema.PicklistEntry pe: ple) {
            channelList.add(pe.getLabel());
        }

        // Sorts the channels in alphabetical order
        channelList.sort();
        System.debug(LoggingLevel.INFO, '*** channelList: ' + channelList);

        // Gets current system time and constructs the local user time list for UI and GMT time list for Apex code
        DateTime startTime = DateTime.newInstance(Datetime.now().year(),
                            Datetime.now().month(),
                            Datetime.now().day(),
                            Datetime.now().hour(), 00, 00);

        createTimeList(startTime);

        // Initeate channelBroadcastMap and broadcastScheduleRecordingStatusMap
        this.populateChannelBroadcasts();
    }

    // Populates the broadcast list in the GMTtime list and the scheduled recordings in the selected device.
    public void populateChannelBroadcasts () {

        System.debug(LoggingLevel.INFO, '*** selectedRecordingDevice: ' + selectedRecordingDevice);

        broadcastMap = new Map <ID, Broadcast__c> ([SELECT Name, Channel__c, Description__c, Show__c, Show__r.Name, Start_Time__c,
                                                        (SELECT Name, Broadcast__c, Broadcast_Updated__c, Conflict_Warning__c,
                                                                Recording_Device__c
                                                         FROM Scheduled_Recordings__r
                                                         WHERE Recording_Device__c =: selectedRecordingDevice)
                                                    FROM Broadcast__c
                                                    WHERE Start_Time__c IN: GMTTimeList
                                                    ORDER BY Start_Time__c ASC]);
        System.debug(LoggingLevel.INFO, '*** broadcastMap: ' + broadcastMap);

        // Composes the channel and broadcasts map
        channelBroadcastMap = new Map<String, List<Broadcast__c>> ();
        broadcastScheduleRecordingStatusMap = new Map<String, Integer> ();

        for (String c : channelList) {

            List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
            for (DateTime dt : GMTTimeList) {

                Boolean foundBroadcast = false;
                for (Broadcast__c bc : broadcastMap.values()) {

                    // Keeps recording status of this broadcast
                    broadcastScheduleRecordingStatusMap.put(bc.Id, this.getRecordingStatus(bc));

                    // If the broadcast chanenl in the same channel and start time in the same column then puts the broadcast in the map
                    if (bc.Channel__c == c && bc.Start_Time__c == dt) {
                        broadcasts.add(bc);
                        foundBroadcast = true;
                        break;
                    }
                }

                // If no broadcast then "No Data"
                if (!foundBroadcast) {
                    broadcasts.add(new Broadcast__c());
                }
            }
            channelBroadcastMap.put(c, broadcasts);
        }

        // Make sure what did above is correctly
        System.debug(LoggingLevel.INFO, '*** broadcastScheduleRecordingStatusMap: ' + broadcastScheduleRecordingStatusMap);
        System.debug(LoggingLevel.INFO, '*** channelBroadcastMap: ' + channelBroadcastMap);
    }

    // Gets recording status
    private Integer getRecordingStatus(Broadcast__c bc) {

        Integer status = 0;

        // If has scheduled recording then loop into check if has conflict warning checked
        if (bc.Scheduled_Recordings__r.size() >= 1) {

            for (Recording__c sr : bc.Scheduled_Recordings__r) {

                // Marks status as conflict
                if (sr.Conflict_Warning__c) {
                    status = 2;
                } else {

                    // If only one scheduled recording than mark status as recorded
                    status = 1;
                }
            }
        }

        return status;
    }

    // Previous page of currently time slot
    public void previous () {
        hasMessages = false;
        paginateNumber --;

        DateTime startTime = DateTime.newInstance(Datetime.now().year(),
                             Datetime.now().month(),
                             Datetime.now().day(),
                             Datetime.now().hour(), 00, 00);
        startTime = startTime.addHours(COLUMN_GRID * paginateNumber);
        createTimeList(startTime);
        this.populateChannelBroadcasts();
    }

    // Nexts page of currently time slot
    public void next () {
        hasMessages = false;
        paginateNumber ++;

        DateTime startTime = DateTime.newInstance(Datetime.now().year(),
                             Datetime.now().month(),
                             Datetime.now().day(),
                             Datetime.now().hour(), 00, 00);
        startTime = startTime.addHours(COLUMN_GRID * paginateNumber);
        createTimeList(startTime);
        this.populateChannelBroadcasts();
    }

    // Shows the selected broad cast details
    public void showBroadCastDetail () {

        isSubscribedChannels = false;
        showBroadCastDetails = true;
        hasMessages = false;

        selectedBroadcast = new Broadcast__c ();
        selectedBroadcast = broadcastMap.get(selectedBroadcastID);
        try {

            isSubscribedChannels = thisCustomer.Subscribed_Channels__c.Contains(selectedBroadcast.Channel__c);
        } catch (Exception npe) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Channel is Subscribed.'));
        }
    }

    // Subscribes the selected broadcast channel
    public PageReference subscribeNow () {

        thisCustomer.Subscribed_Channels__c = thisCustomer.Subscribed_Channels__c + ';' + selectedBroadcast.Channel__c;
        isSubscribedChannels = true;

        try {

            update thisCustomer;

        } catch (DmlException ex) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }

        return null;
    }

    // Records the selected broadcast
    public void record () {

        showBroadCastDetails = false;
        Recording__c scheduleRecording = new Recording__c (Broadcast__c = selectedBroadcast.Id,
                                                           Recording_Device__c = selectedRecordingDevice);
        try {

            insert scheduleRecording;
        } catch (DmlException ex) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));            
        }

        this.populateChannelBroadcasts();
    }

    // Records selected broadcast plus future broadcasts that exist.
    public void recordAll () {

        List<Recording__c> scheduleRecordingList = new List<Recording__c> ();
        showBroadCastDetails = false;
        for (Broadcast__c bc : channelBroadcastMap.get(selectedBroadcast.Channel__c)) {            

            // If the start time is the same with the selected broad cast and currently not recording
            if (bc.Start_Time__c >= selectedBroadcast.Start_Time__c &&
                bc.Name == selectedBroadcast.Name &&
                bc.Scheduled_Recordings__r.size() == 0) {

                Recording__c scheduleRecording = new Recording__c (Broadcast__c = bc.Id,
                                                                   Recording_Device__c = selectedRecordingDevice);
                scheduleRecordingList.add(scheduleRecording);
            } else {
                System.debug(LoggingLevel.INFO, '*** broadcast will not add new recording: ' + bc);
            }
        }

        System.debug(LoggingLevel.INFO, '*** scheduleRecordingList: ' + scheduleRecordingList);

        try {

            insert scheduleRecordingList;
        } catch (DmlException ex) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }

        this.populateChannelBroadcasts();
    }

    // Cancels the recording for this particular broadcast.
    public void cancelRecording () {

        showBroadCastDetails = false;

        try {

            // Deletes scheduled recordings in selected broadcast.
            delete selectedBroadcast.Scheduled_Recordings__r;
        } catch (DmlException ex) {
            hasMessages = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }

        this.populateChannelBroadcasts();
    }

    // Creates time list according to start time
    public void createTimeList(Datetime startTime) {

        TimeZone tz = UserInfo.getTimeZone();
        userLocalStartTime = startTime.addSeconds(tz.getOffset(startTime) / 1000);
        System.debug(LoggingLevel.INFO, '*** userLocalStartTime: ' + userLocalStartTime);

        userLocalTimeList = new List<DateTime> ();
        userLocalTimeList.add(userLocalStartTime);

        GMTTimeList = new List<DateTime> ();
        GMTTimeList.add(startTime);
        for (Integer i = 1; i < COLUMN_GRID; i++) {
            userLocalTimeList.add(userLocalStartTime.addHours(i));
            GMTTimeList.add(startTime.addHours(i));
        }
        System.debug(LoggingLevel.INFO, '*** userLocalTimeList: ' + userLocalTimeList);
        System.debug(LoggingLevel.INFO, '*** GMTTimeList: ' + GMTTimeList);
    }
}