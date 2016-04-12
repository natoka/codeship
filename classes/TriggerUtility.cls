/**************************************************************************************************
 * Name: TriggerUtility
 * Purpose: Utility class for triggers
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-04
 * Modify History:
 * 2016-02-04    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
public with sharing class TriggerUtility {

    public enum Evt {
        afterdelete, afterundelete, afterinsert, afterupdate,
        beforedelete, beforeinsert, beforeupdate
    }

    public interface Handler {
        void handle();
    } 

    Map<String, List<Handler>> eventHandlerMap = new Map<String, List<Handler>> ();

    public void bind (Evt event, Handler eh) {

        List<Handler> handlerList = eventHandlerMap.get(event.name());
        if (handlerList == null) {

            handlerList = new List<Handler> ();
            eventHandlerMap.put(event.name(), handlerList);
        }
        handlerList.add(eh);
    }

    public void manage() {
        Evt ev = null;
        if (Trigger.isInsert && Trigger.isBefore) {
            ev = Evt.beforeinsert;
        } else if (Trigger.isInsert && Trigger.isAfter) {
            ev = Evt.afterinsert;
        } else if (Trigger.isUpdate && Trigger.isBefore) {
            ev = Evt.beforeupdate;
        } else if (Trigger.isUpdate && Trigger.isAfter) {
            ev = Evt.afterupdate;
        } else if (Trigger.isDelete && Trigger.isBefore) {
            ev = Evt.beforedelete;
        } else if (Trigger.isDelete && Trigger.isAfter) {
            ev = Evt.afterdelete;
        } else if (Trigger.isundelete) {
            ev = Evt.afterundelete;
        }

        List<Handler> handlerList = eventHandlerMap.get(ev.name());
        if (handlerList != null && !handlerList.isEmpty()) {
            for (Handler h : handlerList) {
                h.handle();
            }
        }
    }
}