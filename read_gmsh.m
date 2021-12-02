

function Mesh = read_gmsh(fileName)

T=txtfile2cell(fileName);

start_physicals =  find(contains(T,'$PhysicalNames'));
start_entities = find(contains(T,'$Entities'));
start_nodes = find(contains(T,'$Nodes'));
start_elements = find(contains(T,'$Elements'));

entity_info = str2num(T{start_entities+1});
node_info = str2num(T{start_nodes+1});
element_info = str2num(T{start_elements+1});

num_nodes = node_info(2);
num_node_blocks = node_info(1);
num_elements = element_info(2);
num_element_blocks = element_info(1);
num_entities = sum(entity_info);

%%%read physicals
num_physicals = str2num(T{start_physicals+1});
Physicals = T(start_physicals+2:start_physicals+1+num_physicals);
for i = 1:size(Physicals, 1)
    Physicals{i} = strsplit(Physicals{i},' ');
    Physicals{i}{1} = str2num(Physicals{i}{1});
    Physicals{i}{2} = str2num(Physicals{i}{2});
end

%%%read and sort entities
Entities = cell(4,1);
Points = {};Curves = {};Surfaces = {};Volumes = {};
line = start_entities+2;
for i = 1:entity_info(1)
    Temp = str2num(T{line});
    Points{i,1} = Temp;
    line = line+1;
end
for i = 1:entity_info(2)
    Temp = str2num(T{line});
    Curves{i,1} = Temp;
    line = line+1;
end
for i = 1:entity_info(3)
    Temp =  str2num(T{line});
    Surfaces{i,1} = Temp;
    line = line+1;
end
for i = 1:entity_info(4)
    Temp = str2num(T{line});
    Volumes{i,1} = Temp;
    line = line+1;
end
Entities{1} = Points;
Entities{2} = Curves;
Entities{3} = Surfaces;
Entities{4} = Volumes;

%%%read and sort nodes
node_block_info = zeros(num_node_blocks,4);
node_block_numbers = cell(num_node_blocks,1);
node_block_coords = cell(num_node_blocks,1);
line = start_nodes+2;
for i = 1:num_node_blocks
    
    node_block_info_i = str2num(T{line});
    node_block_size= node_block_info_i(1,4);
    
    node_block_info(i,:) = node_block_info_i;
    node_block_numbers_temp = T(line+1:line+node_block_size);
    node_block_coords_temp = T(line+node_block_size +1:line+node_block_size+node_block_size);
    line = line+2*node_block_size+1;
    
    for j = 1:node_block_size        
        node_block_numbers{i}(j,:) = str2num(node_block_numbers_temp{j});
        node_block_coords{i}(j,:) = str2num(node_block_coords_temp{j});
    end    
       
    
end


%%%Read and sort elements
element_block_info = zeros(num_element_blocks,4);
element_block_numbers = cell(num_element_blocks,1);
line = start_elements+2;
for i = 1:num_element_blocks
    
    element_block_info_i = str2num(T{line});element_block_size= element_block_info_i(1,4);
    element_block_info(i,:) = element_block_info_i;
    element_block_numbers_temp = T(line+1:line+element_block_size);
    
    
    for j = 1:element_block_size        
        element_block_numbers{i}(j,:) = str2num(element_block_numbers_temp{j});
    end    
       
    line = line+element_block_size+1;
end

node_ids = [];
nodes = [];
for i = 1:num_node_blocks  
       
    nodes = [nodes;node_block_coords{i}];
    node_ids = [node_ids;node_block_numbers{i}];
    
end

Nodes = double(nodes);
Mesh.Physicals = Physicals;
Mesh.entity_info = entity_info;
Mesh.node_info = node_info;
Mesh.element_info = element_info;
Mesh.Nodes = Nodes;
Mesh.Node_Blocks = node_block_numbers;
Mesh.Node_ids = node_ids;
Mesh.node_block_info = node_block_info;
Mesh.Entities = Entities;
Mesh.Elements = element_block_numbers;
Mesh.element_block_info = element_block_info; 

