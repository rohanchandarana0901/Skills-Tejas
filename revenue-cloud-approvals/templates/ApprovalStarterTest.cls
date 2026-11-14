// The test proves the starter launches the process without error; it cannot complete approval decisions.
@IsTest
private class <Object><Domain>ApprovalStarterTest {
    @IsTest
    static void startsApproval() {
        // Create a minimal valid record of the target object here, e.g. Quote with Name.
        SObject rec = new <Object>(Name = 'Starter Test');
        insert rec;

        <Object><Domain>ApprovalStarter.Request req = new <Object><Domain>ApprovalStarter.Request();
        req.recordId = rec.Id;

        Test.startTest();
        List<<Object><Domain>ApprovalStarter.Result> out = <Object><Domain>ApprovalStarter.submit(new List<<Object><Domain>ApprovalStarter.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertNotEquals(null, out[0].message);
    }
}
