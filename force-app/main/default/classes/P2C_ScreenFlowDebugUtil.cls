public with sharing class P2C_ScreenFlowDebugUtil {

    @InvocableMethod(label='Log data from flow' description='apex function to log in debugs some data from flow')
    public static void logFromFlow(List<String> logs) {
        System.debug(' Flow debug: ' + logs[0]);
    }
}