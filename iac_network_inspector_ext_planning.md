## In-App Console Network Inspector Extension(iac_network_inspector_ext)

### Feature
The extension of the `in_app_console` package. Help log http, https request information in the UI

* Support log fully CURD methods
* Support multipart/form-data
* Support show detail request and detail response
* Support copy a request as CURl

### Dependencies
* Using Dio

### Architecture Overview

iac_network_inspector_ext will expose method to consumers call to register their Dio instance. Then iac_network_inspector_ext will add NetworkInspectorInterceptor to the dio.

Consumer can set tag(String) for their dio instance

When request-response finished(success or error), NetworkInspectorInterceptor will emit event included request-response, tag information

UI will listen NetworkInspectorInterceptor to render UI

