/*
 * Copyright 2004,2005 The Apache Software Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.axiom.soap.impl.llom;

import org.apache.axiom.om.OMElement;
import org.apache.axiom.om.OMNamespace;
import org.apache.axiom.om.OMNode;
import org.apache.axiom.om.OMXMLParserWrapper;
import org.apache.axiom.om.impl.llom.OMNodeImpl;
import org.apache.axiom.om.impl.llom.OMSerializerUtil;
import org.apache.axiom.om.impl.serialize.StreamWriterToContentHandlerConverter;
import org.apache.axiom.soap.SOAP12Constants;
import org.apache.axiom.soap.SOAPFactory;
import org.apache.axiom.soap.SOAPFault;
import org.apache.axiom.soap.SOAPFaultDetail;
import org.apache.axiom.soap.SOAPProcessingException;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;
import java.util.Iterator;

public abstract class SOAPFaultDetailImpl extends SOAPElement implements SOAPFaultDetail {


    protected SOAPFaultDetailImpl(OMNamespace ns, SOAPFactory factory) {
        super(SOAP12Constants.SOAP_FAULT_DETAIL_LOCAL_NAME, ns, factory);
    }

    protected SOAPFaultDetailImpl(SOAPFault parent,
                                  boolean extractNamespaceFromParent, 
                                  SOAPFactory factory) throws SOAPProcessingException {
        super(parent,
                SOAP12Constants.SOAP_FAULT_DETAIL_LOCAL_NAME,
                extractNamespaceFromParent, factory);
    }

    protected SOAPFaultDetailImpl(SOAPFault parent,
                                  OMXMLParserWrapper builder,
                                  SOAPFactory factory) {
        super(parent, SOAP12Constants.SOAP_FAULT_DETAIL_LOCAL_NAME, builder,
                factory);
    }

    public void addDetailEntry(OMElement detailElement) {
        this.addChild(detailElement);
    }

    public Iterator getAllDetailEntries() {
        return this.getChildren();
    }

    protected void serialize(org.apache.axiom.om.impl.OMOutputImpl omOutput, boolean cache) throws XMLStreamException {
        // select the builder
        short builderType = PULL_TYPE_BUILDER;    // default is pull type
        if (builder != null) {
            builderType = this.builder.getBuilderType();
        }
        if ((builderType == PUSH_TYPE_BUILDER)
                && (builder.getRegisteredContentHandler() == null)) {
            builder.registerExternalContentHandler(new StreamWriterToContentHandlerConverter(omOutput));
        }


        XMLStreamWriter writer = omOutput.getXmlStreamWriter();
        if (this.getNamespace() != null) {
            String prefix = this.getNamespace().getPrefix();
            String nameSpaceName = this.getNamespace().getName();
            writer.writeStartElement(prefix, SOAP12Constants.SOAP_FAULT_DETAIL_LOCAL_NAME,
                    nameSpaceName);
        } else {
            writer.writeStartElement(
                    SOAP12Constants.SOAP_FAULT_DETAIL_LOCAL_NAME);
        }
        OMSerializerUtil.serializeAttributes(this, omOutput);
        OMSerializerUtil.serializeNamespaces(this, omOutput);


        String text = this.getText();
        writer.writeCharacters(text);

        OMNode child = (OMNodeImpl) firstChild;
        while (child != null && ((!(child instanceof OMElement)) || child.isComplete())) {
            ((OMNodeImpl) child).serializeAndConsume(omOutput);
            child = child.getNextOMSibling();
        }

        writer.writeEndElement();


    }

}
