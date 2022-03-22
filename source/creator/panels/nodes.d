/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.nodes;
import creator.viewport.vertex;
import creator.actions;
import creator.panels;
import creator;
import creator.widgets;
import creator.core;
import creator.utils;
import inochi2d;
import std.string;
import std.format;
import std.conv;
import i18n;

/**
    The logger frame
*/
class NodesPanel : Panel {
protected:
    void treeSetEnabled(Node n, bool enabled) {
        n.enabled = enabled;
        foreach(child; n.children) {
            treeSetEnabled(child, enabled);
        }
    }

    void nodeActionsPopup(bool isRoot = false)(Node n) {
        if (igIsItemClicked(ImGuiMouseButton.Right)) {
            igOpenPopup("NodeActionsPopup");
        }

        if (igBeginPopup("NodeActionsPopup")) {
            
            auto selected = incSelectedNodes();
            
            if (igBeginMenu(__("Add"), true)) {

                igPushFont(incIconFont());
                    igText(incTypeIdToIcon("Node").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem(__("Node"), "", false, true)) incAddChildWithHistory(new Node(n), n);
                
                igPushFont(incIconFont());
                    igText(incTypeIdToIcon("Mask").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem(__("Mask"), "", false, true)) {
                    MeshData empty;
                    incAddChildWithHistory(new Mask(empty, n), n);
                }
                
                igPushFont(incIconFont());
                    igText(incTypeIdToIcon("PathDeform").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem(__("PathDeform"), "", false, true)) incAddChildWithHistory(new PathDeform(n), n);
                
                igEndMenu();
            }

            static if (!isRoot) {
                if (igMenuItem(n.enabled ? /* Option to hide the node (and subnodes) */ __("Hide") :  /* Option to show the node (and subnodes) */ __("Show"))) {
                    n.enabled = !n.enabled;
                }
                
                if (igMenuItem(__("Delete"), "", false, !isRoot)) {

                    foreach(sn; selected) {
                        incDeleteChildWithHistory(sn);
                    }

                    // Make sure we don't keep selecting a node we've removed
                    incSelectNode(null);
                }
                

                if (igBeginMenu(__("More Info"), true)) {
                    if (selected.length > 1) {
                        foreach(sn; selected) {
                            
                            // %s is the name of the node in the More Info menu
                            // %lu is the UUID of the node in the More Info menu
                            igText(__("%s ID: %lu"), sn.name.ptr, sn.uuid);
                        }
                    } else {
                        // %lu is the UUID of the node in the More Info menu
                        igText(__("ID: %lu"), n.uuid);
                    }

                    igEndMenu();
                }
            }
            igEndPopup();
        }
    }

    void treeAddNode(bool isRoot = false)(ref Node n) {
        igTableNextRow();

        auto io = igGetIO();

        // // Draw Enabler for this node first
        // igTableSetColumnIndex(1);
        // igPushFont(incIconFont());
        //     igText(n.enabled ? "\ue8f4" : "\ue8f5");
        // igPopFont();


        // Prepare node flags
        ImGuiTreeNodeFlags flags;
        if (n.children.length == 0) flags |= ImGuiTreeNodeFlags.Leaf;
        flags |= ImGuiTreeNodeFlags.DefaultOpen;
        flags |= ImGuiTreeNodeFlags.OpenOnArrow;

        // Then draw the node tree index
        igTableSetColumnIndex(0);
        bool open = igTreeNodeEx(cast(void*)n.uuid, flags, "");

            // Show node entry stuff
            igSameLine(0, 4);

            auto selectedNodes = incSelectedNodes();
            igPushID(n.uuid);
                    bool selected = incNodeInSelection(n);

                    igPushFont(incIconFont());
                        static if (!isRoot) {
                            if (n.enabled) igText(incTypeIdToIcon(n.typeId).ptr);
                            else igTextDisabled(incTypeIdToIcon(n.typeId).ptr);
                        } else {
                            igText("");
                        }
                    igPopFont();
                    igSameLine(0, 2);

                    if (igSelectable(isRoot ? __("Puppet") : n.name.toStringz, selected, ImGuiSelectableFlags.None, ImVec2(0, 0))) {
                        switch(incEditMode) {
                            default:
                                if (selected) {
                                    if (incSelectedNodes().length > 1) {
                                        if (io.KeyCtrl) incRemoveSelectNode(n);
                                        else incSelectNode(n);
                                    } else {
                                        incFocusCamera(n);
                                    }
                                } else {
                                    if (io.KeyCtrl) incAddSelectNode(n);
                                    else incSelectNode(n);
                                }
                                break;
                        }
                    }
                    this.nodeActionsPopup!isRoot(n);

                    static if (!isRoot) {
                        if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                            igSetDragDropPayload("_PUPPETNTREE", cast(void*)&n, (&n).sizeof, ImGuiCond.Always);
                            if (selectedNodes.length > 1) {
                                foreach(node; selectedNodes) {
                                    igText(node.name.toStringz);
                                }
                            } else {
                                igText(n.name.toStringz);
                            }
                            igEndDragDropSource();
                        }
                    }
            igPopID();

            // Only allow reparenting one node
            if (selectedNodes.length < 2) {
                if(igBeginDragDropTarget()) {
                    ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                    if (payload !is null) {
                        Node payloadNode = *cast(Node*)payload.Data;
                        
                        if (payloadNode.canReparent(n)) {
                            incMoveChildWithHistory(payloadNode, n);
                        }
                        
                        igTreePop();
                        return;
                    }
                    igEndDragDropTarget();
                }
            }

        if (open) {
            // Draw children
            foreach(child; n.children) {
                treeAddNode(child);
            }
            igTreePop();
        }
        

    }

    void treeAddDrawable(ref Drawable n) {
        igTextColored(ImVec4(0.6f, 0f, 0f, 0f), __("Node list is unavailable while editing meshes"));
        // igTableNextRow();
        // igTableSetColumnIndex(0);
        
        // ImGuiTreeNodeFlags flags;
        // flags |= ImGuiTreeNodeFlags.Leaf;
        // flags |= ImGuiTreeNodeFlags.DefaultOpen;
        // flags |= ImGuiTreeNodeFlags.OpenOnArrow;

        // igTreeNodeEx(cast(void*)n.uuid, flags, "");
        //     // Show node entry stuff
        //     igSameLine(0, 4);

        //     igPushID(n.uuid);

        //         bool selected = incNodeInSelection(n);

        //         igPushFont(incIconFont());
        //             igText(incTypeIdToIcon(n.typeId).ptr);
        //         igPopFont();
        //         igSameLine(0, 2);

        //         if (igSelectable(n.name.toStringz, selected, ImGuiSelectableFlags.None, ImVec2(0, 0))) {
        //             if (selected) {
        //                 incFocusCamera(n, vec2(0, 0));
        //             }
        //             incSelectNode(n);
        //             incVertexEditSetTarget(n);
        //         }
        //         // this.nodeActionsPopup(n);
        //     igPopID();
        // igTreePop();
    }

    override
    void onUpdate() {

        if (incEditMode == EditMode.ModelEdit){ 
            auto io = igGetIO();
            if (io.KeyCtrl && igIsKeyPressed(igGetKeyIndex(ImGuiKey.A), false)) {
                incSelectAll();
            }
        }

        igBeginChild_Str("NodesMain", ImVec2(0, -30), false);
            igPushStyleVar(ImGuiStyleVar.CellPadding, ImVec2(4, 1));
            igPushStyleVar(ImGuiStyleVar.IndentSpacing, 14);

            if (igBeginTable("NodesContent", 2, ImGuiTableFlags.ScrollX, ImVec2(0, 0), 0)) {
                igTableSetupColumn("Nodes", ImGuiTableColumnFlags.WidthFixed, 0, 0);
                //igTableSetupColumn("Visibility", ImGuiTableColumnFlags_WidthFixed, 32, 1);
                
                if (incEditMode == EditMode.ModelEdit) {
                    treeAddNode!true(incActivePuppet.root);
                } else {
                    foreach(drawable; incDrawables()) {
                            treeAddDrawable(drawable);
                    }
                }

                igEndTable();
            }
            if (igIsItemClicked(ImGuiMouseButton.Left)) {
                incSelectNode(null);
            }
            igPopStyleVar();
            igPopStyleVar();
        igEndChild();

        igSeparator();
        igSpacing();
        
        igPushFont(incIconFont());
            if (incEditMode() == EditMode.ModelEdit) {
                auto selected = incSelectedNodes();
                if (igButton("\ue92e", ImVec2(24, 24))) {
                    foreach(payloadNode; selected) incDeleteChildWithHistory(payloadNode);
                }

                if(igBeginDragDropTarget()) {
                    ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                    if (payload !is null) {
                        Node payloadNode = *cast(Node*)payload.Data;

                        if (selected.length > 1) {
                            foreach(pn; selected) incDeleteChildWithHistory(pn);
                            incSelectNode(null);
                        } else {

                            // Make sure we don't keep selecting a node we've removed
                            if (incNodeInSelection(payloadNode)) {
                                incSelectNode(null);
                            }

                            incDeleteChildWithHistory(payloadNode);
                        }
                        
                        igPopFont();
                        return;
                    }
                    igEndDragDropTarget();
                }
            }
        igPopFont();

    }

public:

    this() {
        super("Nodes", _("Nodes"), true);
        flags |= ImGuiWindowFlags.NoScrollbar;
    }
}

/**
    Generate nodes frame
*/
mixin incPanel!NodesPanel;


