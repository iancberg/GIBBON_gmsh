

function Meshes_New = renumber_gmsh(Meshes)

%start_entities = [0, 0, 0, 0];
start_node = 0;
start_element = 0;

    for mesh_ct = 1:length(Meshes)
        Mesh = Meshes{mesh_ct};
        %Entities = Mesh.Entities;
        %Entities_New = cell(4,1);
        
%         for i = 1:length(Entities)
%         Entities_New{i,1} = [start_entities(i)+1:start_entities(i)+length(Entities{i})]';
%         end
        
        node_block_info_rn = Mesh.node_block_info;
        node_block_numbers_rn = Mesh.Node_Blocks;
        element_block_info_rn = Mesh.element_block_info;
        element_block_numbers_rn = Mesh.Elements;
        
        
        num_node_blocks = Mesh.node_info(1);
        
        nodes_ids_new = [];
        for i = 1:num_node_blocks  

            %entity_dim_ind = node_block_info_rn(i,1)+1;
            %entity_num = node_block_info_rn(i,2);
            %new_entity_number = Entities_New{entity_dim_ind}(Entities{entity_dim_ind}==entity_num);
            %node_block_info_rn(i,2) = new_entity_number;
            node_block_numbers_rn{i} = node_block_numbers_rn{i} + start_node;

            nodes_ids_new = [nodes_ids_new;node_block_numbers_rn{i}];

        end
        
        num_element_blocks = Mesh.element_info(1);
        for i = 1:num_element_blocks  
            
            %entity_dim_ind = element_block_info_rn(i,1)+1;
            %entity_num = element_block_info_rn(i,2);
            %new_entity_number = Entities_New{entity_dim_ind}(Entities{entity_dim_ind}==entity_num);
            %element_block_info_rn(i,2) = new_entity_number;
            element_block_numbers_rn{i}(:,1) = element_block_numbers_rn{i}(:,1) + start_element;        
            element_block_numbers_rn{i}(:,2:end) = element_block_numbers_rn{i}(:,2:end) + start_node;
             
        end
        
        Mesh_New = Mesh;
        Mesh_New.Node_Blocks = node_block_numbers_rn;
        Mesh_New.Node_ids = nodes_ids_new;
        Mesh_New.node_block_info = node_block_info_rn;
        %Mesh_New.Entities = Entities_New;
        Mesh_New.Elements = element_block_numbers_rn;
        Mesh_New.element_block_info = element_block_info_rn;
        
        Meshes_New{mesh_ct} = Mesh_New;
        
        %start_entities = start_entities+Mesh.entity_info;
        start_node = start_node+Mesh.node_info(4);
        start_element = start_element+Mesh.element_info(4);

        
    end


end
