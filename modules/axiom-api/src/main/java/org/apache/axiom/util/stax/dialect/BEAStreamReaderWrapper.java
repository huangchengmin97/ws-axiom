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

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

import org.apache.axiom.util.stax.wrapper.XMLStreamReaderWrapper;

class BEAStreamReaderWrapper extends XMLStreamReaderWrapper {
    /**
     * The character set encoding as inferred from the start bytes of the stream.
     */
    private final String encodingFromStartBytes;
    
    public BEAStreamReaderWrapper(XMLStreamReader parent, String encodingFromStartBytes) {
        super(parent);
        this.encodingFromStartBytes = encodingFromStartBytes;
    }

    public int next() throws XMLStreamException {
        if (!hasNext()) {
            // The reference implementation throws an XMLStreamException in this case.
            // This can't be considered as compliant with the specifications.
            throw new IllegalStateException("Already reached end of document");
        } else {
            return super.next();
        }
    }

    public String getEncoding() {
        // TODO: this needs some more unit testing!
        String encoding = super.getEncoding();
        if (encoding != null) {
            return encoding;
        } else {
            if (encodingFromStartBytes == null) {
                // This means that the reader was created from a character stream
                // ==> always return null
                return null;
            } else {
                // If an XML encoding declaration was present, return the specified
                // encoding, otherwise fall back to the encoding we detected in
                // the factory wrapper
                encoding = getCharacterEncodingScheme();
                return encoding == null ? encodingFromStartBytes : encoding;
            }
        }
    }
}
