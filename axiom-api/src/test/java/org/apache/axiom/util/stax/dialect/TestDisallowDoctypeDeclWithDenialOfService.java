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
package org.apache.axiom.util.stax.dialect;

import java.io.InputStream;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

public class TestDisallowDoctypeDeclWithDenialOfService extends DialectTestCase {
    public TestDisallowDoctypeDeclWithDenialOfService(StAXImplementationAdapter staxImpl) {
        super(staxImpl);
    }

    protected void runTest() throws Throwable {
        XMLInputFactory factory = staxImpl.newNormalizedXMLInputFactory();
        factory = staxImpl.getDialect().disallowDoctypeDecl(factory);
        InputStream in = TestDisallowDoctypeDeclWithDenialOfService.class.getResourceAsStream("doctype_dos.xml");
        try {
            boolean gotException = false;
            boolean reachedDocumentElement = false;
            try {
                XMLStreamReader reader = factory.createXMLStreamReader(in);
                try {
                    while (reader.hasNext()) {
                        if (reader.next() == XMLStreamConstants.START_ELEMENT) {
                            reachedDocumentElement = true;
                        }
                    }
                } finally {
                    reader.close();
                }
            } catch (XMLStreamException ex) {
                gotException = true;
            } catch (RuntimeException ex) {
                gotException = true;
            }
            assertTrue("Expected exception", gotException);
            assertFalse("The parser failed to throw an exception before reaching the document element", reachedDocumentElement);
        } finally {
            in.close();
        }
    }
}
