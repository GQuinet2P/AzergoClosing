@isTest
public with sharing class P2C_ScreenFlowDebugUtil_Test {

    @isTest
    public static void testLog() {
        List<String> logs = new List<String>{'testA','testB'};
        P2C_ScreenFlowDebugUtil.logFromFlow(logs);
    }
}