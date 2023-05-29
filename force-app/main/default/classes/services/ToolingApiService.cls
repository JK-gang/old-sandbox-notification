public inherited sharing class ToolingApiService {
    private static final String LOG_LOCATION = 'ToolingApiService';

    /**
     * Make Tooling API call to get query response
     * @param query tooling api query
     *
     * @return tooling api response
     */
    public MetadataQueryStructure getMetadataQuery(String query) {
        String baseUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v57.0/tooling/';
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(baseUrl + 'query?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        httpRequest.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse httpResponse;

        MetadataQueryStructure result;
        try {
            httpResponse = http.send(httpRequest);
            if (httpResponse.getStatusCode() == 200) {
                // apex do not support deserialization to object so must be made manually
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
                result = new MetadataQueryStructure(jsonMap);
                result.isSuccess = true;
            } else {
                result = new MetadataQueryStructure();
                List<Object> responseList = (List<Object>) JSON.deserializeUntyped(httpResponse.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) responseList[0];
                result.message = responseMap.get('message').toString();
                result.isSuccess = false;
                //Logger.log(Logger.Level.ERROR, 'Request: ' + httpRequest.getBody() + '\nResponse: ' + httpResponse.getBody(), LOG_LOCATION);
            }
        } catch (Exception e) {
            result = new MetadataQueryStructure();
            result.isSuccess = false;
            result.message = e.getMessage();
            result.e = e;
            //Logger.log(Logger.Level.ERROR, 'Request: ' + httpRequest.getBody() + '\nResponse: ' + httpResponse.getBody(), LOG_LOCATION, e);
        }
        return result;
    }

    public class MetadataQueryStructure {
        public Integer size { get; set; }
        public String entityTypeName { get; set; }
        public transient List<Object> records { get; set; }
        // additional fields
        public Boolean isSuccess { get; set; }
        public String message { get; set; }
        public Exception e { get; set; }

        public MetadataQueryStructure() {
        }
        public MetadataQueryStructure(Map<String, Object> jsonObject) {
            this.size = (Integer) jsonObject.get('size');
            this.entityTypeName = (String) jsonObject.get('entityTypeName');
            this.records = (List<Object>) jsonObject.get('records');
        }
    }
    public class SandboxInfoStructure {
        public String SandboxName { get; set; }
        public String Description { get; set; }
        public Datetime LastModifiedDate { get; set; }
        public Id LastModifiedById { get; set; }

        public SandboxInfoStructure(Map<String, Object> jsonObject) {
            this.SandboxName = jsonObject.get('SandboxName')?.toString();
            this.Description = jsonObject.get('Description')?.toString();
            this.LastModifiedDate = (Datetime) JSON.deserialize('"' + (jsonObject.get('LastModifiedDate')) + '"', Datetime.class);
            this.LastModifiedById = (Id) jsonObject.get('LastModifiedById');
        }
    }
}