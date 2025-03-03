%------------------------------------------------------------------------%
%------ Gmsh to Matlab script: Import QUAD mesh with parametric nodes----%
%------------------------------------------------------------------------%

clc
close all
clear

% File name
file = 'chamfer.msh';

% Read the entire file as text
mesh_data = fileread(file);

% Locate the $ParametricNodes section
nodes_start = regexp(mesh_data, '\$ParametricNodes', 'end') + 1;
nodes_end = regexp(mesh_data, '\$EndParametricNodes') - 1;

% Debug: show positions of $ParametricNodes and $EndParametricNodes
fprintf('$ParametricNodes starts at: %d\n', nodes_start);
fprintf('$EndParametricNodes ends at: %d\n', nodes_end);

% Extract nodes
if isempty(nodes_start) || isempty(nodes_end) || nodes_start >= nodes_end
    error('Failed to locate valid $ParametricNodes section in the .msh file.');
end

nodes_block = splitlines(strtrim(mesh_data(nodes_start:nodes_end)));

% Check if node block is empty
if isempty(nodes_block)
    error('Could not locate $ParametricNodes section in the .msh file.');
end

% Clean and trim the first line
nodes_block{1} = strtrim(nodes_block{1});

% Debug: display first few lines of nodes_block
fprintf('First few lines of nodes_block:\n');
for i = 1:min(5, numel(nodes_block))
    fprintf('%s\n', nodes_block{i});
end

num_nodes = str2double(nodes_block{1});

% Validate num_nodes
if isnan(num_nodes) || num_nodes <= 0
    error('Invalid number of nodes read from the .msh file. Content: "%s"', nodes_block{1});
end

% Parse node data
nodes = zeros(num_nodes, 3);
node_id = zeros(num_nodes, 1);
for i = 2:num_nodes+1
    data = sscanf(nodes_block{i}, '%d %f %f %f');
    if numel(data) < 4
        error('Node data on line %d is incomplete or malformed.', i);
    end
    node_id(i-1) = data(1);
    nodes(i-1, :) = data(2:4);
end

two_d_nodes = nodes(:, 1:2); % Only X and Y for 2D visualization

% Locate the $Elements section
elements_start = regexp(mesh_data, '\$Elements', 'end') + 1;
elements_end = regexp(mesh_data, '\$EndElements') - 1;

% Debug: show positions of $Elements and $EndElements
fprintf('$Elements starts at: %d\n', elements_start);
fprintf('$EndElements ends at: %d\n', elements_end);

% Extract elements
if isempty(elements_start) || isempty(elements_end) || elements_start >= elements_end
    error('Failed to locate valid $Elements section in the .msh file.');
end

elements_block = splitlines(strtrim(mesh_data(elements_start:elements_end)));

% Check if element block is empty
if isempty(elements_block)
    error('Could not locate $Elements section in the .msh file.');
end

num_elements = str2double(strtrim(elements_block{1}));

% Validate num_elements
if isnan(num_elements) || num_elements <= 0
    error('Invalid number of elements read from the .msh file. Content: "%s"', elements_block{1});
end

% Parse element data
quad_elements = [];
for i = 2:num_elements+1
    data = sscanf(elements_block{i}, '%d %d %d %d %d %d %d %d');
    if numel(data) < 8
        warning('Element data on line %d is incomplete. Skipping.', i);
        continue;
    end
    if data(2) == 3 % Element type 3 = 4-node quadrilateral
        quad_elements = [quad_elements; data(5:8)'];
    end
end

fprintf('Parsed %d quadrilateral elements.\n', size(quad_elements, 1));

% Check if elements were found
if isempty(quad_elements)
    error('No 2D quadrilateral elements found in the .msh file.');
end

% Visualize the 2D quadrilateral mesh
figure(1)
patch('Faces', quad_elements, 'Vertices', two_d_nodes, 'FaceColor', 'none', 'EdgeColor', 'b');
xlabel('X', 'fontsize', 14)
ylabel('Y', 'fontsize', 14)
title('GMsh to MATLAB import (Quad Mesh with Parametric Nodes)', 'fontsize', 14)
set(gcf, 'color', 'white');

%------------------------------------------------------------------------%
