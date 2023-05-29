@IsTest(SeeAllData=false)
private class ToolingApiServiceTest {
    @IsTest
    static void testGetMetadataQuerySuccess() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock(200));
        Test.startTest();
        ToolingApiService.MetadataQueryStructure result = new ToolingApiService().getMetadataQuery('Test Query');
        Test.stopTest();

        Assert.isTrue(result.isSuccess);
        Assert.isNotNull(result.size);
        Assert.isNotNull(result.records);
        Assert.isNull(result.message);

        Map<String, Object> record = (Map<String, Object>) result.records[0];
        ToolingApiService.SandboxInfoStructure info = new ToolingApiService.SandboxInfoStructure(record);
        Assert.areEqual('config5', info.SandboxName);
        Assert.areEqual('jiri micanek - training', info.Description);
        Assert.isNotNull(info.LastModifiedDate);
        Assert.areEqual('005b0000002Ol7JAAS', info.LastModifiedById);
    }

    @IsTest
    static void testGetMetadataQueryError() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock(400));
        Test.startTest();
        ToolingApiService.MetadataQueryStructure result = new ToolingApiService().getMetadataQuery('Test Query');
        Test.stopTest();

        Assert.isFalse(result.isSuccess);
        Assert.isNotNull(result.message);
        Assert.isNull(result.e);
    }

    public class ToolingApiMock implements HttpCalloutMock {
        private Integer statusCode;

        public ToolingApiMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            if (this.statusCode == 200) {
                if (request.getEndpoint().contains('query?q=')) {
                    response.setStatusCode(200);
                    response.setBody('{"size":2,"totalSize":2,"done":true,"queryLocator":null,"entityTypeName":"SandboxInfo","records":[{"attributes":{"type":"SandboxInfo","url":"/services/data/v56.0/tooling/sobjects/SandboxInfo/0GQb0000000KymoGAC"},"SandboxName":"config5","Description":"jiri micanek - training","LicenseType":"DEVELOPER","LastModifiedById":"005b0000002Ol7JAAS","LastModifiedDate":"2015-11-25T10:59:42.000+0000"},{"attributes":{"type":"SandboxInfo","url":"/services/data/v56.0/tooling/sobjects/SandboxInfo/0GQb00000004CG9GAM"},"SandboxName":"SFDC","Description":"Michal Skuhra - Sandbox for Salesforce people","LicenseType":"DEVELOPER","LastModifiedById":"005b0000002Q2iiAAC","LastModifiedDate":"2016-02-15T12:48:33.000+0000"}]}');
                    return response;
                }
                throw new UnsupportedOperationException();
            } else {
                response.setStatusCode(this.statusCode);
                response.setBody('[{"message":"sObject type \'SandboxInfo\' is not supported.","errorCode":"INVALID_TYPE"}]');
                return response;
            }
        }
    }
}