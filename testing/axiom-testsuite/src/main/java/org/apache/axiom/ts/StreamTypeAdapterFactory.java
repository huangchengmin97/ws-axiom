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
package org.apache.axiom.ts;

import java.io.Closeable;
import java.io.InputStream;
import java.io.Reader;

import org.apache.axiom.om.OMFactory;
import org.apache.axiom.om.OMXMLBuilderFactory;
import org.apache.axiom.om.OMXMLParserWrapper;
import org.apache.axiom.testing.multiton.AdapterFactory;
import org.apache.axiom.testing.multiton.Adapters;
import org.apache.axiom.ts.xml.StreamType;

import com.google.auto.service.AutoService;

@AutoService(AdapterFactory.class)
public class StreamTypeAdapterFactory implements AdapterFactory<StreamType> {
    @Override
    public void createAdapters(StreamType instance, Adapters adapters) {
        if (instance == StreamType.BYTE_STREAM) {
            adapters.add(new StreamTypeAdapter() {
                @Override
                public OMXMLParserWrapper createOMBuilder(OMFactory omFactory, Closeable stream) {
                    return OMXMLBuilderFactory.createOMBuilder(omFactory, (InputStream)stream);
                }
            });
        } else if (instance == StreamType.CHARACTER_STREAM) {
            adapters.add(new StreamTypeAdapter() {
                @Override
                public OMXMLParserWrapper createOMBuilder(OMFactory omFactory, Closeable stream) {
                    return OMXMLBuilderFactory.createOMBuilder(omFactory, (Reader)stream);
                }
            });
        }
    }
}
