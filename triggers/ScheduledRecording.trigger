/**************************************************************************************************
 * Name: ScheduledRecording
 * Purpose: 1. For any device on which Scheduled Recordings are being inserted, updated, or deleted, 
               Scheduled Recordings for Broadcasts which are completed (one hour past the Broadcast 
               Start Time [Start_Time__c]) must be deleted.
            2. For any device on which Scheduled Recordings are being inserted, updated, or deleted, 
               Scheduled Recordings (existing or new) on a device that will result in a recording 
               conflict on the Recording Device must have the Conflict Warning [Conflict_Warning__c]
               field checked
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-04
 * Modify History:
 * 2016-02-04    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
trigger ScheduledRecording on Recording__c (after insert, after update, after delete) {

    TriggerUtility triggerInstance = new TriggerUtility ();

    triggerInstance.bind(TriggerUtility.Evt.afterinsert, new ScheduledRecordingHandler());
    triggerInstance.bind(TriggerUtility.Evt.afterupdate, new ScheduledRecordingHandler());
    triggerInstance.bind(TriggerUtility.Evt.afterdelete, new ScheduledRecordingHandler());



    // Executes the assosicated hanlders
    triggerInstance.manage();
}
