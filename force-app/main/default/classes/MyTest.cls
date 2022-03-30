@isTest
private class MyTest {

    @isTest
    static void myUnitTest() {
        MyClass demo = new MyClass();
        System.assertEquals(demo.getAppVersion(), '1.0.0');
        // Uncomment the following lin to cause a build failure
        // System.assert(false);
    }
}