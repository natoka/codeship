/**************************************************************************************************
 * Name: ScheduledRecordingHandler
 * Purpose: Handler for trigger ScheduledRecording
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-04
 * Modify History:
 * 2016-02-04    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
public with sharing class ScheduledRecordingHandler implements TriggerUtility.Handler {

	public void handle () {

		Set<Id> recordingDeviceSet = new Set<Id> ();
		List<Recording__c> deleteRecordingList = new List<Recording__c> ();
		List<Recording__c> recordingList = new List<Recording__c> ();

		// For after insert handler
		if (Trigger.isInsert && Trigger.isAfter) {

			List<Recording__c> insertedRecordingList = (List<Recording__c>) Trigger.new;

			for (Recording__c insertRecording : insertedRecordingList) {

				recordingDeviceSet.add(insertRecording.Recording_Device__c);
			}

		// For after update handler
		} else if (Trigger.isUpdate && Trigger.isAfter) {

			Map<Id, Recording__c> newRecordingMap = (Map<Id, Recording__c>) Trigger.newMap;
			List<Recording__c> oldRecordingList = (List<Recording__c>) Trigger.old;

    		// Prepares the recording device Ids that are impacted because of the update
    		for (Recording__c oldRecording : oldRecordingList) {
    			Recording__c newRecording = newRecordingMap.get(oldRecording.Id);
    			if(oldRecording.Recording_Device__c != newRecording.Recording_Device__c ||
    			   oldRecording.Broadcast__c != newRecording.Broadcast__c) {
                    recordingDeviceSet.add(oldRecording.Recording_Device__c);
                    recordingDeviceSet.add(newRecording.Recording_Device__c);
    			}
    		}

    	// For after delete handler
		} else if (Trigger.isDelete && Trigger.isAfter) {

    		List<Recording__c> deletedRecordingList = (List<Recording__c>) Trigger.old;

    		// Prepares the recording device Ids that are impacted because of the delete
    		for(Recording__c deletedRecording : deletedRecordingList) {
    			recordingDeviceSet.add(deletedRecording.Recording_Device__c);
    		}
    	}
    	System.debug(LoggingLevel.INFO, '*** recordingDeviceSet: ' + recordingDeviceSet);

    	try {

    		// Queries the completed recording
	    	deleteRecordingList = [SELECT Name, Recording_Device__c, Broadcast__c, Broadcast__r.Start_Time__c
	    					       FROM Recording__c
	    					       WHERE Recording_Device__c IN :recordingDeviceSet
	    					       AND Broadcast__r.Start_Time__c < :System.now().addHours(-1)
	    					       ORDER BY Broadcast__r.Start_Time__c ASC];
	    	System.debug(LoggingLevel.INFO, '*** deleteRecordingList: ' + deleteRecordingList);

	    	// Queries the scheduled recording
	    	recordingList = [SELECT Name, Recording_Device__c, Broadcast__c, Broadcast__r.Start_Time__c
	    					 FROM Recording__c
	    					 WHERE Recording_Device__c IN :recordingDeviceSet
	    					 AND Broadcast__r.Start_Time__c > :System.now()
	    					 ORDER BY Broadcast__r.Start_Time__c ASC];
	    	System.debug(LoggingLevel.INFO, '*** recordingList: ' + recordingList);

    	} catch (QueryException qe) {
    		System.debug(LoggingLevel.ERROR, '*** qe: ' + qe.getMessage());
    	}

    	// Composes the device recording time Set.
    	Set<String> deviceRecordingTime = new Set<String> ();
    	for (Recording__c rec : recordingList) {
    		deviceRecordingTime.add(rec.Recording_Device__c + String.valueOf(rec.Broadcast__r.Start_Time__c));
    	}
    	System.debug(LoggingLevel.INFO, '*** deviceRecordingTime: ' + deviceRecordingTime);

    	// Composes the device recording time and recording list map
    	Map<String, List<Recording__c>> deviceTimeRecordingMap = new Map<String, List<Recording__c>> ();
    	for (String dr : deviceRecordingTime) {

    		List<Recording__c> recordings = new List<Recording__c> ();
	    	for (Recording__c rec : recordingList) {

	    		// If the start time is the same puts them in the same recording list
	    		if (dr == rec.Recording_Device__c + String.valueOf(rec.Broadcast__r.Start_Time__c)) recordings.add(rec);
	    	}

	    	// Puts the device time as key, same start time recording list as value.
			deviceTimeRecordingMap.put(dr, recordings);	    	
	    }
	    System.debug(LoggingLevel.INFO, '*** deviceTimeRecordingMap: ' + deviceTimeRecordingMap);

	    List<Recording__c> updateRecordings = new List<Recording__c> ();
	    for (String dr : deviceRecordingTime) {

	    	List<Recording__c> rcs = new List<Recording__c> ();
	    	rcs = deviceTimeRecordingMap.get(dr);

	    	// If only recording as the start time, then uncheck the Conflict Warning check box
	    	if (rcs.size() == 1) {
	    		updateRecordings.add(new Recording__c (ID = rcs[0].Id, Conflict_Warning__c = FALSE));

	    	// If has more than one recording in the same start time, then check the Conflict Warning checkbox for all the recording records
	    	} else if (rcs.size() > 1) {
	    		for (Recording__c r : rcs) {
	    			updateRecordings.add(new Recording__c (ID = r.Id, Conflict_Warning__c = TRUE));
	    		}
	    	}
	    }

	    try {

	    	// Deletes completed scheduled recordings
	    	if(!deleteRecordingList.isEmpty()) delete deleteRecordingList;

	    	// Updates conflict warning indicators
	    	if(!updateRecordings.isEmpty()) update updateRecordings;
	    } catch (DMLException ex) {
            for (Integer i = 0; i < ex.getNumDml(); i++) {
                if (trigger.isDelete) {
                    trigger.old[0].addError(ex.getDMLMessage(i));
                }
                else {
                    trigger.new[0].addError(ex.getDMLMessage(i));
                }
            }
	    }
	}
}