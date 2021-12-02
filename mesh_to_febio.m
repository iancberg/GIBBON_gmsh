function [febio_spec, Meshes_New] = mesh_to_febio(febio_spec, parts_path, files, defaultMaterial)


for i = 1:size(files,2)

part_file = [parts_path, files{i}];     
Meshes{i} = read_gmsh(part_file);

end

Meshes_New = renumber_gmsh(Meshes);

vol_ct = 0;
surf_ct = 0;
curve_ct= 0;
for i = 1:length(Meshes_New)
    
     [~,part_name,~] = fileparts(files{i});
     node_set_name = [part_name, '_node_set'];%     febio_spec.Mesh.Nodes{i}.ATTR.name=node_set_name; %The node set name
     febio_spec.Mesh.Nodes{i}.ATTR.name=node_set_name; %The node set name
     febio_spec.Mesh.Nodes{i}.node.ATTR.id=Meshes_New{i}.Node_ids; %The node id's
     febio_spec.Mesh.Nodes{i}.node.VAL=Meshes_New{i}.Nodes; %The nodel coordinates
        
    for j = 1:size(Meshes_New{i}.Physicals,1)
        
        physical = Meshes_New{i}.Physicals{j};
        phys_name = physical{3}(2:end-1);
        dim = physical{1};
        tag = physical{2};
        
        switch dim
            case 3
                
                vol_ct = vol_ct+1;
                entities = Meshes_New{i}.Entities{4,1};
                element_ids = [];
                element_mat = [];
                
                for k = 1:size(entities, 1)
                    num_phys = entities{k}(8);
                    phys_tags = entities{k}(9:9+num_phys-1);
                    if sum(find(phys_tags==tag))
                       entity_tag = entities{k}(1);
                       elements_3 = (Meshes_New{i}.element_block_info(:,1) == dim).*Meshes_New{i}.element_block_info;
                       entity_ind = find(elements_3(:,2)==entity_tag);
                       element_ids = [element_ids;Meshes_New{i}.Elements{entity_ind}(:,1)];
                       element_mat = [element_mat;Meshes_New{i}.Elements{entity_ind}(:,2:end)];                         
                    end
   
                end
                                                
                febio_spec.Mesh.Elements{vol_ct}.ATTR.type='tet4'; %Element type
                febio_spec.Mesh.Elements{vol_ct}.ATTR.name=phys_name; %Name of this part
                febio_spec.Mesh.Elements{vol_ct}.elem.ATTR.id=element_ids; %Element id's
                febio_spec.Mesh.Elements{vol_ct}.elem.VAL=element_mat; %The element matrix
                febio_spec.MeshDomains.SolidDomain{vol_ct}.ATTR.name=phys_name;
                febio_spec.MeshDomains.SolidDomain{vol_ct}.ATTR.mat=defaultMaterial;
                                
            case 2
                
                surf_ct = surf_ct+1;
                entities = Meshes_New{i}.Entities{3,1};
                element_mat = []; 
                element_start = 0;
                
                for k = 1:size(entities, 1)
                    num_phys = entities{k}(8);
                    phys_tags = entities{k}(9:9+num_phys-1);
                    if sum(find(phys_tags==tag))
                       entity_tag = entities{k}(1);
                       elements_2 = (Meshes_New{i}.element_block_info(:,1) == dim).*(Meshes_New{i}.element_block_info(:,2) == entity_tag);
                       entity_ind = find(elements_2);
                       element_mat = [element_mat;Meshes_New{i}.Elements{entity_ind}(:,2:end)];
                       element_start = element_start+1;
                       %element_ids = [element_ids' element_start:element_start+size(element_mat,1)]';
                       element_start = element_start+size(element_mat,1);
                    end

                end
                
                element_ids = [1:size(element_mat,1)]';
                febio_spec.Mesh.Surface{surf_ct}.ATTR.name=phys_name; %Name of this surface
                febio_spec.Mesh.Surface{surf_ct}.tri3.ATTR.id=element_ids; %Element id's
                febio_spec.Mesh.Surface{surf_ct}.tri3.VAL=element_mat; %The element matrix   

                case 1
                
                curve_ct = curve_ct+1;
                entities = Meshes_New{i}.Entities{2,1};
                element_mat = []; 
                element_start = 0;
                
                for k = 1:size(entities, 1)
                    num_phys = entities{k}(8);
                    phys_tags = entities{k}(9:9+num_phys-1);
                    if sum(find(phys_tags==tag))
                       entity_tag = entities{k}(1);
                       elements_1 = (Meshes_New{i}.element_block_info(:,1) == dim).*(Meshes_New{i}.element_block_info(:,2) == entity_tag);
                       entity_ind = find(elements_1);
                       element_mat = [element_mat;Meshes_New{i}.Elements{entity_ind}(:,2:end)];
                       element_start = element_start+1;
                       %element_ids = [element_ids' element_start:element_start+size(element_mat,1)]';
                       element_start = element_start+size(element_mat,1);
                    end

                end
                
                element_ids = element_mat(:,1);
                febio_spec.Mesh.NodeSet{curve_ct}.ATTR.name=phys_name; %Name of this surface
                febio_spec.Mesh.NodeSet{curve_ct}.node.ATTR.id=element_ids; %Element id's
                               
       end
    end
            
end 
    

end