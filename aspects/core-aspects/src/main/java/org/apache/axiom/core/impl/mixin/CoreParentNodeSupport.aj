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
package org.apache.axiom.core.impl.mixin;

import org.apache.axiom.core.Axis;
import org.apache.axiom.core.Builder;
import org.apache.axiom.core.ChildNotAllowedException;
import org.apache.axiom.core.ClonePolicy;
import org.apache.axiom.core.CloneableCharacterData;
import org.apache.axiom.core.Content;
import org.apache.axiom.core.CoreCDATASection;
import org.apache.axiom.core.CoreCharacterDataContainer;
import org.apache.axiom.core.CoreCharacterDataNode;
import org.apache.axiom.core.CoreChildNode;
import org.apache.axiom.core.CoreDocument;
import org.apache.axiom.core.CoreDocumentFragment;
import org.apache.axiom.core.CoreElement;
import org.apache.axiom.core.CoreModelException;
import org.apache.axiom.core.CoreModelStreamException;
import org.apache.axiom.core.CoreNode;
import org.apache.axiom.core.CoreParentNode;
import org.apache.axiom.core.CyclicRelationshipException;
import org.apache.axiom.core.ElementAction;
import org.apache.axiom.core.ElementMatcher;
import org.apache.axiom.core.InputContext;
import org.apache.axiom.core.Mapper;
import org.apache.axiom.core.NodeConsumedException;
import org.apache.axiom.core.NodeFilter;
import org.apache.axiom.core.NodeIterator;
import org.apache.axiom.core.Semantics;
import org.apache.axiom.core.impl.ElementsIterator;
import org.apache.axiom.core.impl.Flags;
import org.apache.axiom.core.impl.NodesIterator;
import org.apache.axiom.core.impl.TreeWalkerImpl;
import org.apache.axiom.core.stream.CharacterData;
import org.apache.axiom.core.stream.StreamException;
import org.apache.axiom.core.stream.XmlHandler;
import org.apache.axiom.core.stream.XmlReader;

public aspect CoreParentNodeSupport {
    private InputContext CoreParentNode.context;
    private Object CoreParentNode.content;
    
    // TODO: rename
    public final int CoreParentNode.getState() {
        return internalGetFlags(Flags.STATE_MASK);
    }
    
    public final void CoreParentNode.coreSetState(int state) {
        internalSetFlags(Flags.STATE_MASK, state);
        if (state == COMPLETE) {
            completed();
        }
    }
    
    public void CoreParentNode.completed() {}
    
    public boolean CoreParentNode.isExpanded() {
        return true;
    }
    
    public void CoreParentNode.forceExpand() {}

    public final Builder CoreParentNode.coreGetBuilder() {
        forceExpand();
        return context == null ? null : context.getBuilder();
    }

    public final InputContext CoreParentNode.coreGetInputContext() {
        return context;
    }

    public final void CoreParentNode.coreSetInputContext(InputContext context) {
        this.context = context;
        if (context == null) {
            switch (getState()) {
                case INCOMPLETE: coreSetState(COMPLETE); break;
                case DISCARDING: coreSetState(DISCARDED); break;
            }
        } else {
            coreSetState(INCOMPLETE);
        }
    }

    public final void CoreParentNode.internalSetContent(Object content) {
        this.content = content;
    }

    public final Object CoreParentNode.internalGetContent() {
        return content;
    }

    public final Content CoreParentNode.internalGetContent(boolean create) {
        if (getState() == COMPACT) {
            Content content = new Content();
            CoreCharacterDataNode cdata = coreGetNodeFactory().createNode(CoreCharacterDataNode.class);
            cdata.internalSetParent(this);
            cdata.coreSetCharacterData(this.content);
            content.firstChild = cdata;
            content.lastChild = cdata;
            this.content = content;
            coreSetState(COMPLETE);
            return content;
        } else {
            Content content = (Content)this.content;
            if (content == null && create) {
                content = new Content();
                this.content = content;
            }
            return content;
        }
    }
    
    public final CoreChildNode CoreParentNode.coreGetFirstChildIfAvailable() {
        forceExpand();
        Content content = internalGetContent(false);
        return content == null ? null : content.firstChild;
    }

    public CoreChildNode CoreParentNode.coreGetLastKnownChild() {
        Content content = internalGetContent(false);
        return content == null ? null : content.lastChild;
    }

    public void CoreParentNode.internalBuildNext() throws CoreModelException {
        Builder builder = coreGetBuilder();
        if (builder == null) {
            throw new IllegalStateException("The node has no builder");
        } else if (!builder.isCompleted()) {
            builder.next();
        } else {
            // If the builder is suddenly complete, but the completion status of the node
            // doesn't change, then this means that we built the wrong nodes
            throw new IllegalStateException("Builder is already complete");
        }         
    }
    
    public CoreChildNode CoreParentNode.coreGetFirstChild() throws CoreModelException {
        CoreChildNode firstChild = coreGetFirstChildIfAvailable();
        if (firstChild == null) {
            switch (getState()) {
                case CoreParentNode.DISCARDING:
                case CoreParentNode.DISCARDED:
                    throw new NodeConsumedException();
                case CoreParentNode.INCOMPLETE:
                    do {
                        internalBuildNext();
                    } while ((firstChild = coreGetFirstChildIfAvailable()) == null
                            && getState() == CoreParentNode.INCOMPLETE);
            }
        }
        return firstChild;
    }

    public final CoreChildNode CoreParentNode.coreGetFirstChild(NodeFilter filter) throws CoreModelException {
        CoreChildNode child = coreGetFirstChild();
        while (child != null && !filter.accept(child)) {
            child = child.coreGetNextSibling();
        }
        return child;
    }
    
    public final CoreChildNode CoreParentNode.coreGetLastChild() throws CoreModelException {
        coreBuild();
        return coreGetLastKnownChild();
    }

    public final CoreChildNode CoreParentNode.coreGetLastChild(NodeFilter filter) throws CoreModelException {
        CoreChildNode child = coreGetLastChild();
        while (child != null && !filter.accept(child)) {
            child = child.coreGetPreviousSibling();
        }
        return child;
    }
    
    public final void CoreParentNode.internalCheckNewChild(CoreChildNode newChild, CoreChildNode replacedChild) throws CoreModelException {
        // Check that the new node is not an ancestor of this node
        CoreParentNode current = this;
        do {
            if (current == newChild) {
                throw new CyclicRelationshipException();
            }
            if (current instanceof CoreChildNode) {
                current = ((CoreChildNode)current).coreGetParent();
            } else {
                break;
            }
        } while (current != null);
        if (!coreGetNodeType().isChildTypeAllowed(newChild.coreGetNodeType())) {
            throw new ChildNotAllowedException();
        }
        internalCheckNewChild0(newChild, replacedChild);
    }
    
    void CoreParentNode.internalCheckNewChild0(CoreChildNode newChild, CoreChildNode replacedChild) throws CoreModelException {
    }
    
    public final void CoreParentNode.coreAppendChild(CoreChildNode child) throws CoreModelException {
        internalCheckNewChild(child, null);
        forceExpand();
        coreBuild();
        internalAppendChildWithoutBuild(child);
    }
    
    public final void CoreParentNode.internalAppendChildWithoutBuild(CoreChildNode child) {
        CoreParentNode parent = child.coreGetParent();
        Content content = internalGetContent(true);
        if (parent == this && child == content.lastChild) {
            // The child is already the last node. 
            // We don't need to detach and re-add it.
            return;
        }
        child.internalDetach(null, this);
        if (content.firstChild == null) {
            content.firstChild = child;
        } else {
            child.internalSetPreviousSibling(content.lastChild);
            content.lastChild.internalSetNextSibling(child);
        }
        content.lastChild = child;
    }

    public final void CoreParentNode.coreAppendChildren(CoreDocumentFragment fragment) throws CoreModelException {
        fragment.coreBuild();
        Content fragmentContent = fragment.internalGetContent(false);
        if (fragmentContent == null || fragmentContent.firstChild == null) {
            // Fragment is empty; nothing to do
            return;
        }
        coreBuild();
        CoreChildNode child = fragmentContent.firstChild;
        while (child != null) {
            child.internalSetParent(this);
            child = child.coreGetNextSiblingIfAvailable();
        }
        Content content = internalGetContent(true);
        if (content.firstChild == null) {
            content.firstChild = fragmentContent.firstChild;
        } else {
            fragmentContent.firstChild.internalSetPreviousSibling(content.lastChild);
            content.lastChild.internalSetNextSibling(fragmentContent.firstChild);
        }
        content.lastChild = fragmentContent.lastChild;
        fragmentContent.firstChild = null;
        fragmentContent.lastChild = null;
    }

    public final void CoreParentNode.coreDiscard(boolean consumeInput) throws CoreModelException {
        if (!isExpanded()) {
            return;
        }
        CoreChildNode child = coreGetFirstChildIfAvailable();
        while (child != null) {
            if (child instanceof CoreParentNode) {
                ((CoreParentNode)child).coreDiscard(consumeInput);
            }
            child = child.coreGetNextSiblingIfAvailable();
        }
        if (context != null) {
            context.discard();
            if (consumeInput) {
                Builder builder = context.getBuilder();
                do {
                    builder.next();
                } while (getState() != DISCARDED);
            }
        }
    }

    public final void CoreParentNode.coreRemoveChildren(Semantics semantics) throws CoreModelException {
        if (getState() == COMPACT) {
            coreSetState(COMPLETE);
            content = null;
        } else {
            // We need to call this first because if may modify the state (applies to OMSourcedElements)
            CoreChildNode child = coreGetFirstChildIfAvailable();
            boolean updateState;
            if (getState() == INCOMPLETE) {
                CoreChildNode lastChild = coreGetLastKnownChild();
                if (lastChild instanceof CoreParentNode) {
                    ((CoreParentNode)lastChild).coreBuild();
                }
                context.discard();
                updateState = true;
            } else {
                updateState = false;
            }
            if (child != null) {
                CoreDocument newOwnerDocument = semantics.getDetachPolicy().getNewOwnerDocument(this);
                do {
                    CoreChildNode nextSibling = child.coreGetNextSiblingIfAvailable();
                    child.internalSetPreviousSibling(null);
                    child.internalSetNextSibling(null);
                    child.internalUnsetParent(newOwnerDocument);
                    child = nextSibling;
                } while (child != null);
            }
            content = null;
            if (updateState) {
                coreSetState(COMPLETE);
            }
        }
    }
    
    public final Object CoreParentNode.internalGetCharacterData(ElementAction elementAction) throws CoreModelException {
        if (getState() == COMPACT) {
            return content;
        } else {
            Object textContent = null;
            StringBuilder buffer = null;
            int depth = 0;
            CoreChildNode child = coreGetFirstChild();
            boolean visited = false;
            while (child != null) {
                if (visited) {
                    visited = false;
                } else if (child instanceof CoreElement) {
                    switch (elementAction) {
                        case RETURN_NULL:
                            return null;
                        case RECURSE:
                            CoreChildNode firstChild = ((CoreElement)child).coreGetFirstChild();
                            if (firstChild != null) {
                                child = firstChild;
                                depth++;
                                continue;
                            }
                            // Fall through
                        case SKIP:
                            // Just continue
                    }
                } else {
                    if (child instanceof CoreCharacterDataNode || child instanceof CoreCDATASection) {
                        Object textValue = ((CoreCharacterDataContainer)child).coreGetCharacterData();
                        if (textValue instanceof CharacterData || ((String)textValue).length() != 0) {
                            if (textContent == null) {
                                // This is the first non empty text node. Just save the string.
                                textContent = textValue;
                            } else {
                                // We've already seen a non empty text node before. Concatenate using
                                // a StringBuilder.
                                if (buffer == null) {
                                    // This is the first text node we need to append. Initialize the
                                    // StringBuilder.
                                    buffer = new StringBuilder(textContent.toString());
                                }
                                buffer.append(textValue.toString());
                            }
                        }
                    }
                }
                CoreChildNode nextSibling = child.coreGetNextSibling();
                if (depth > 0 && nextSibling == null) {
                    depth--;
                    child = (CoreChildNode)child.coreGetParent();
                    visited = true;
                } else {
                    child = nextSibling;
                }
            }
            if (textContent == null) {
                // We didn't see any text nodes. Return an empty string.
                return "";
            } else if (buffer != null) {
                return buffer.toString();
            } else {
                return textContent;
            }
        }
    }
    
    public final void CoreParentNode.coreSetCharacterData(Object data, Semantics semantics) throws CoreModelException {
        coreRemoveChildren(semantics);
        if (data != null && (data instanceof CharacterData || ((String)data).length() > 0)) {
            coreSetState(COMPACT);
            content = data;
        }
    }
    
    public final <T extends CoreNode,S> NodeIterator<S> CoreParentNode.coreGetNodes(Axis axis, Class<T> type, Mapper<S,? super T> mapper, Semantics semantics) {
        return new NodesIterator<T,S>(this, axis, type, mapper, semantics);
    }
    
    public final <T extends CoreElement,S> NodeIterator<S> CoreParentNode.coreGetElements(Axis axis, Class<T> type, ElementMatcher<? super T> matcher, String namespaceURI, String name, Mapper<S,? super T> mapper, Semantics semantics) {
        return new ElementsIterator<T,S>(this, axis, type, matcher, namespaceURI, name, mapper, semantics);
    }

    public final <T> void CoreParentNode.cloneChildrenIfNecessary(ClonePolicy<T> policy, T options, CoreNode clone) throws CoreModelException {
        CoreParentNode targetParent = (CoreParentNode)clone;
        if (policy.cloneChildren(options, coreGetNodeType()) && targetParent.isExpanded()) {
            if (getState() == COMPACT) {
                Object content = this.content;
                if (content instanceof CloneableCharacterData) {
                    content = ((CloneableCharacterData)content).clone(policy, options);
                }
                targetParent.coreSetCharacterData(content, null);
            } else {
                CoreChildNode child = coreGetFirstChild();
                while (child != null) {
                    child.coreClone(policy, options, targetParent);
                    child = child.coreGetNextSibling();
                }
            }
        }
    }

    public void CoreParentNode.serializeStartEvent(XmlHandler handler) throws CoreModelException, StreamException {
        throw new UnsupportedOperationException();
    }

    public void CoreParentNode.serializeEndEvent(XmlHandler handler) throws StreamException {
        throw new UnsupportedOperationException();
    }

    public final XmlReader CoreParentNode.coreGetReader(XmlHandler handler, boolean cache, boolean incremental) {
        return new TreeWalkerImpl(handler, this, cache, incremental);
    }
    
    public void CoreParentNode.internalSerialize(XmlHandler handler, boolean cache) throws CoreModelException, StreamException {
        try {
            XmlReader reader = coreGetReader(handler, cache, false);
            while (!reader.proceed()) {
                // Just loop
            }
        } catch (CoreModelStreamException ex) {
            throw ex.getCoreModelException();
        }
    }
    
    public final void CoreParentNode.coreBuild() throws CoreModelException {
        switch (getState()) {
            case DISCARDING:
            case DISCARDED:
                throw new NodeConsumedException();
            case INCOMPLETE:
                if (context != null) {
                    Builder builder = context.getBuilder();
                    do {
                        builder.next();
                    } while (context != null);
                }
        }
    }
    
    public final void CoreParentNode.coreMoveChildrenFrom(CoreParentNode other, Semantics semantics) throws CoreModelException {
        coreRemoveChildren(semantics);
        context = other.coreGetInputContext();
        content = other.internalGetContent();
        int state = other.getState();
        coreSetState(state);
        if (state != COMPACT) {
            CoreChildNode child = coreGetFirstChildIfAvailable();
            while (child != null) {
                child.internalSetParent(this);
                child = child.coreGetNextSiblingIfAvailable();
            }
            if (context != null ) {
                context.setTarget(this);
            }
        }
        other.coreSetInputContext(null);
        other.internalSetContent(null);
        other.coreSetState(DISCARDED);
    }
}
