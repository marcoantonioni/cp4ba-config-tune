# cp4ba-config-tune

Utilities for IBM Cloud Pak® for Business Automation

<i>Last update: 2026-06-17</i> (see changelog.md for details)

## Description of the contents of this repository

In this repository a series of procedures are available for configuration and tuning of IBM Cloud Pak for Business Automation capabilities in Openshift clusters.

The contents must be understood as examples of training on the topic of CP4BA IT Operations. 

Obviously it is without any kind of support. Use them freely, modify them where necessary according to your needs.

This repository can be useful for professionals who create disposable environments dedicated to demonstrations/tests of the CP4BA product (IBMers, IBM Partners and Customers with active license to access to IBM Container Registry).

Please read the DISCLAIMER section carefully.

## Project structure

### BAStudio & BAW
```
└───── export
   ├── output
   ├── scripts
   └── templates-custom-xml
```

#### Export folder

Folder 
#### Output folder

#### Scripts folder

#### Templates folder


## Business Automation Workflow

### Configuration

The Liberty and Lombardi 100Custom.xml server configurations are defined in the templates-custom-xml folder.
The templates are valued based on environment variables defined in the properties files used to install the environment.
You can create templates as desired by referencing the variables with the usual ${VAR_NAME} plateholder.

### Performance Tuning

TBD

## Command examples

Export configuration
```bash
# authoring environment
./cp4ba-list-export-configs.sh -c ../../cp4ba-installations/configs25.0.1/env1-authoring-baw-bai.properties -s -d -e

# runtime environment
./cp4ba-list-export-configs.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties -s -d -e
```

Set configuration
```bash
# authoring environment
./cp4ba-create-custom-xml-secrets.sh -c ../../cp4ba-installations/configs25.0.1/env1-authoring-baw-bai.properties

# runtime environment
./cp4ba-create-custom-xml-secrets.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties

./cp4ba-create-custom-xml-secrets.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties -p -s baw1

```

Restart pods of Statefulset
```bash

# authoring environment
./cp4ba-restart-statefulset.sh -c ../../cp4ba-installations/configs25.0.1/env1-authoring-baw-bai.properties -t baw -s bas -w

# runtime environment BAW, graceful restart
./cp4ba-restart-statefulset.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties -t baw -s baw1 -w

# runtime environment BAW, force restart
./cp4ba-restart-statefulset.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties -t baw -s baw1 -w -f

# runtime environment WFPS, graceful restart
./cp4ba-restart-statefulset.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-wfps.properties -t wfps -s wfps-demo-1 -w

# runtime environment WFPS, force restart
./cp4ba-restart-statefulset.sh -c ../../cp4ba-installations/configs25.0.1/env1-runtime-wfps.properties -t wfps -s wfps-demo-1 -w -f

```

# References

## Configuration and Tuning

Don't use 'liberty_custom_xml' tag with this tools.

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=automation-customizing

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=customizing-business-automation-workflow-properties

https://community.ibm.com/community/user/blogs/frank-lu/2026/03/23/cp4ba-2500-tuning-recommendations-for-large-worklo

https://opensource.com/article/21/7/parse-xml-linux

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=customizing-100customxml-file-configuration

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=studio-optional-customizing-business-automation-properties

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=deployment-customizing-workflow-process-service-runtime#tsk_customize_wfps__liberty

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=configuration-deploying-100customxml-file-deployment-environment

https://www.ibm.com/docs/en/baw/25.0.x?topic=parameters-runtime

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=configuration-modifying-individual-properties

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=properties-limiting-number-rest-calls-server

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/25.0.1?topic=properties-adjusting-rest-timeout-length

https://www.ibm.com/docs/en/cloud-paks/foundational-services/4.x_cd?topic=options-configuring-foundational-services


https://github.com/icp4a/workflow-performance/blob/main/container.md


---
**DISCLAIMER**


<u>The entire contents of this repository are not intended for production environments.</u>

The main purpose is self-education and for test or demo environments.
No form of support or warranty is applicable.

Only the <b>.sh</b> scripts and <b>.properties</b> configuration files are released in open source mode according to https://opensource.org/license/mit/

<i>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge , publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.</i>

The configurations for any .yaml Custom Resource of any IBM products are property of IBM as per the official wording:

Licensed Materials - Property of IBM

(C) Copyright IBM Corp. 2022, 2023. All Rights Reserved.

US Government Users Restricted Rights - Use, duplication or
disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

---


# References

TBD