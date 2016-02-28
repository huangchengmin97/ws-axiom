/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.apache.axiom.ts.soap.headerblock;

import org.apache.axiom.om.OMContainer;
import org.apache.axiom.om.OMMetaFactory;
import org.apache.axiom.om.OMNode;
import org.apache.axiom.soap.SOAPBody;
import org.apache.axiom.soap.SOAPHeader;
import org.apache.axiom.soap.SOAPHeaderBlock;
import org.apache.axiom.soap.SOAPProcessingException;
import org.apache.axiom.ts.soap.SOAPSpec;
import org.apache.axiom.ts.soap.SOAPTestCase;

/**
 * Tests that {@link OMContainer#addChild(OMNode)} throws an exception if an attempt is made to add
 * a {@link SOAPHeaderBlock} to a SOAP element other than {@link SOAPHeader}.
 */
public class TestWrongParent1 extends SOAPTestCase {
    public TestWrongParent1(OMMetaFactory metaFactory, SOAPSpec spec) {
        super(metaFactory, spec);
    }

    protected void runTest() throws Throwable {
        SOAPBody parent = soapFactory.createSOAPBody();
        SOAPHeaderBlock hb = soapFactory.createSOAPHeaderBlock("MyHeader", soapFactory.createOMNamespace("urn:test", "p"));
        try {
            parent.addChild(hb);
            fail("Expected SOAPProcessingException");
        } catch (SOAPProcessingException ex) {
            // Expected
        }
    }
}
