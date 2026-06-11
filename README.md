# cp4ba-config-tune

Utilities for IBM Cloud Pak® for Business Automation

<i>Last update: 2026-06-03</i> (see changelog.md for details)

## Description of the contents of this repository

In this repository a series of procedures are available for configuration and tuning of IBM Cloud Pak for Business Automation capabilities in Openshift clusters.

The contents must be understood as examples of training on the topic of CP4BA IT Operations. 

Obviously it is without any kind of support. Use them freely, modify them where necessary according to your needs.

This repository can be useful for professionals who create disposable environments dedicated to demonstrations/tests of the CP4BA product (IBMers, IBM Partners and Customers with active license to access to IBM Container Registry).

Please read the DISCLAIMER section carefully.

## Project structure

### BAStudio & BAW
```
└── baw
    ├── export
    ├── output
    ├── scripts
    └── templates
```

#### Export folder

Folder 
#### Output folder

#### Scripts folder

#### Templates folder


## Business Automation Workflow

### Configuration

### Performance Tuning

## Command examples

```bash
# authoring environment
./baw-list-export-configs.sh -c ../../../cp4ba-installations/configs25.0.1/env1-authoring-baw-bai-onedb-int.properties -s -d -e

# runtime environment
./baw-list-export-configs.sh -c ../../../cp4ba-installations/configs25.0.1/env1-runtime-baw-bai-perf-test.properties -s -d -e
```

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