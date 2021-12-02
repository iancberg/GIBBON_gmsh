
%path and file declarations (can likely be handled better in future)
%path with .geo (gmsh) files
geo_path = 'Gmsh_Example\';
%list of .geo files used to generate meshes
geo_files = {'rigid_dome.geo','square_membrane.geo'};
%path to gmsh generated mesh files
mesh_path = 'Gmsh_Example\';
%list of gmsh generated mesh files
files = {'rigid_dome.msh','square_membrane.msh'};
%path to an installation of gmsh
gmsh_path = 'C:\Users\icberg\git_installs\GIBBON\gmsh_integration\';

%%
%list parameters to set within the geo files
parameter_names = {'membrane_L', 'membrane_W', 'membrane_H', 'radius'};
parameter_values = {50, 50, 0.5, 12.5};

%update the geo files 
for geo_ind = 1:length(geo_files)

    geo_text = txtfile2cell([geo_path,geo_files{geo_ind}]);
    
    for param_ind = 1:length(parameter_names)
        parameter_line =  find(startsWith(geo_text,parameter_names{param_ind}));
        if ~isempty(parameter_line)
            geo_text{parameter_line} = [parameter_names{param_ind}, ' = ', num2str(parameter_values{param_ind}),';'];
            
        end
    end
    
    cell2txtfile([geo_path,geo_files{geo_ind}],geo_text);

end
%%

%execute each of the .geo files in gmsh to generate msh files
for i = 1:size(geo_files,2)
    runGmsh([geo_path,geo_files{i}],gmsh_path)
end

%%
defaultFolder = 'Gmsh_Example\output\';
savePath=fullfile(defaultFolder);

% Defining file names
febioFebFileNamePart=['Gmsh_Example'];
febioFebFileName=fullfile(savePath,[febioFebFileNamePart,'.feb']); %FEB file name
febioLogFileName=[febioFebFileNamePart,'.txt']; %FEBio log file name
febioLogFileName_disp=[febioFebFileNamePart,'_disp_out.txt']; %Log file name for exporting displacement
febioLogFileName_stress=[febioFebFileNamePart,'_stress_out.txt']; %Log file name for exporting stress
febioLogFileName_position=[febioFebFileNamePart,'_position_out.txt']; %Log file name for exporting stress
febioLogFileName_stress_prin=[febioFebFileNamePart,'_stress_prin_out.txt']; %Log file name for exporting principal stress
febioLogFileName_strain=[febioFebFileNamePart,'_strain_out.txt']; %Log file name for exporting stress
febioLogFileName_strain_prin=[febioFebFileNamePart,'_strain_prin_out.txt']; %Log file name for exporting principal stress


% FEA control settings
numTimeSteps=10; %Number of time steps desired
max_refs=30; %Max reforms
max_ups=0; %Set to zero to use full-Newton iterations
opt_iter=6; %Optimum number of iterations
max_retries=25; %Maximum number of retires
dtmin=(1/numTimeSteps)/500; %Minimum time step size
dtmax=1/numTimeSteps; %Maximum time step size
runMode='external';

%Get a template with default settings 
[febio_spec]=febioStructTemplate;
febio_spec.ATTR.version='3.0'; 
febio_spec.Module.ATTR.type='solid'; 

%Control section
febio_spec.Control.analysis='STATIC';
febio_spec.Control.time_steps=numTimeSteps;
febio_spec.Control.step_size=1/numTimeSteps;
febio_spec.Control.solver.max_refs=max_refs;
febio_spec.Control.solver.max_ups=max_ups;
febio_spec.Control.solver.qnmethod='BFGS';
febio_spec.Control.time_stepper.dtmin=dtmin;
febio_spec.Control.time_stepper.dtmax=dtmax; 
febio_spec.Control.time_stepper.max_retries=max_retries;
febio_spec.Control.time_stepper.opt_iter=opt_iter;

% Create a default Material section
% Material parameter set
E_youngs1=0.1; %Material Young's modulus
nu1=0.48; %Material Poisson's ratio

defaultMaterial='defaultMaterial';
febio_spec.Material.material{1}.ATTR.name=defaultMaterial;
febio_spec.Material.material{1}.ATTR.type='rigid body';
febio_spec.Material.material{1}.ATTR.id=1;


%Output section 
% -> log file
febio_spec.Output.logfile.ATTR.file=febioLogFileName;
febio_spec.Output.logfile.node_data{1}.ATTR.file=febioLogFileName_disp;
febio_spec.Output.logfile.node_data{1}.ATTR.data='ux;uy;uz';
febio_spec.Output.logfile.node_data{1}.ATTR.delim=',';

febio_spec.Output.logfile.element_data{1}.ATTR.file=febioLogFileName_stress;
febio_spec.Output.logfile.element_data{1}.ATTR.data='sz';
febio_spec.Output.logfile.element_data{1}.ATTR.delim=',';

febio_spec.Output.logfile.element_data{2}.ATTR.file=febioLogFileName_stress_prin;
febio_spec.Output.logfile.element_data{2}.ATTR.data='s1;s2;s3';
febio_spec.Output.logfile.element_data{2}.ATTR.delim=',';

febioStruct2xml(febio_spec,febioFebFileName); %Exporting to file and domNode


%%
[febio_spec, Meshes_New] = mesh_to_febio(febio_spec, mesh_path, files, defaultMaterial);

%% Define and assign the materials
matid = 1;
febio_spec.Material.material{matid}.ATTR.name='rigid';
febio_spec.Material.material{matid}.ATTR.type='rigid body';
febio_spec.Material.material{matid}.ATTR.id=matid;
febio_spec.Material.material{matid}.density = 1;
febio_spec.Material.material{matid}.center_of_mass = [0,0,0];

matid = 2;
febio_spec.Material.material{matid}.ATTR.name='membrane';
febio_spec.Material.material{matid}.ATTR.type='neo-Hookean';
febio_spec.Material.material{matid}.ATTR.id=matid;
febio_spec.Material.material{matid}.density = 1;
febio_spec.Material.material{matid}.E=100;
febio_spec.Material.material{matid}.v=.48;

febio_spec.MeshDomains.SolidDomain{1}.ATTR.mat = 'rigid';
febio_spec.MeshDomains.SolidDomain{2}.ATTR.mat = 'membrane';

% collect doman names into a table
% This is just for convenience to get the domains in a table to check
% that the import was correct get the order of the domains in the
% structure

% Solid_Domains = febio_spec.MeshDomains.SolidDomain;
% T = table('Size',[length(Solid_Domains) 2],'VariableTypes',{'string','string'});
% T.Properties.VariableNames = {'Domain_Name', 'Material'}; 
% 
% for i = 1:length(febio_spec.MeshDomains.SolidDomain)
%     T.Domain_Name(i) = febio_spec.MeshDomains.SolidDomain{i}.ATTR.name;
%     T.Material(i) = febio_spec.MeshDomains.SolidDomain{i}.ATTR.mat;
% end

% this is an alternative way to assign materials by first editing the above
% table
% % %% Reassign materials
% % 
% % for i = 1:length(febio_spec.MeshDomains.SolidDomain)
% %     febio_spec.MeshDomains.SolidDomain{i}.ATTR.mat = convertStringsToChars(T.Material(i));
% % end

%% Constraints
%Rigid section
% ->Rigid body fix boundary conditions
febio_spec.Rigid.rigid_constraint{1}.ATTR.name='RigidFix';
febio_spec.Rigid.rigid_constraint{1}.ATTR.type='fix';
febio_spec.Rigid.rigid_constraint{1}.rb=1;
febio_spec.Rigid.rigid_constraint{1}.dofs='Rx,Ry,Rz,Ru,Rv,Rw';

%%Boundary conditions
% -> Fixed boundary conditions surfaces
bid = 1;
febio_spec.Boundary.bc{bid}.ATTR.name='fix_xyz_membrane';
febio_spec.Boundary.bc{bid}.ATTR.type='fix';
febio_spec.Boundary.bc{bid}.ATTR.node_set='@surface:membrane_fixed';
febio_spec.Boundary.bc{bid}.dofs='x,y,z';

bid = 2;
febio_spec.Boundary.bc{bid}.ATTR.name='fix_xyz_dome';
febio_spec.Boundary.bc{bid}.ATTR.type='fix';
febio_spec.Boundary.bc{bid}.ATTR.node_set='@surface:dome_fixed';
febio_spec.Boundary.bc{bid}.dofs='x,y,z';


%% Contacts
% -> Surface pairs
cid = 1;
febio_spec.Mesh.SurfacePair{cid}.ATTR.name= 'membrane_dome';
febio_spec.Mesh.SurfacePair{cid}.primary='membrane_bottom';
febio_spec.Mesh.SurfacePair{cid}.secondary='Dome';


febio_spec.Contact.contact{cid}.ATTR.type='sliding-facet-on-facet';
febio_spec.Contact.contact{cid}.ATTR.name= febio_spec.Mesh.SurfacePair{cid}.ATTR.name;
febio_spec.Contact.contact{cid}.ATTR.surface_pair=febio_spec.Mesh.SurfacePair{cid}.ATTR.name;
febio_spec.Contact.contact{cid}.two_pass=0;
febio_spec.Contact.contact{cid}.laugon= 1;
febio_spec.Contact.contact{cid}.tolerance=0.2;
febio_spec.Contact.contact{cid}.gaptol=0;
febio_spec.Contact.contact{cid}.minaug= 0;
febio_spec.Contact.contact{cid}.maxaug= 10;
febio_spec.Contact.contact{cid}.search_tol=0.01;
febio_spec.Contact.contact{cid}.search_radius=0;
%%febio_spec.Contact.contact{cid}.symmetric_stiffness=0;
febio_spec.Contact.contact{cid}.auto_penalty=0;
febio_spec.Contact.contact{cid}.penalty=1000;
febio_spec.Contact.contact{cid}.fric_coeff=0;



%% Loads

%LoadData section
% -> load_controller
lcid = 1;
febio_spec.LoadData.load_controller{lcid}.ATTR.id=lcid;
febio_spec.LoadData.load_controller{lcid}.ATTR.type='loadcurve';
febio_spec.LoadData.load_controller{lcid}.interpolate='LINEAR';
febio_spec.LoadData.load_controller{lcid}.points.point.VAL=[0 0; 0.2 0.05; 0.75 0.3; 1, 1];

febio_spec.Loads.surface_load{1}.ATTR.name='Membrane_Pressure';
febio_spec.Loads.surface_load{1}.ATTR.type='pressure';
febio_spec.Loads.surface_load{1}.ATTR.surface='membrane_top';
febio_spec.Loads.surface_load{1}.pressure.ATTR.lc=1;
febio_spec.Loads.surface_load{1}.pressure.VAL=0.67;
febio_spec.Loads.surface_load{1}.symmetric_stiffness=1;


%%
febioStruct2xml(febio_spec,febioFebFileName); %Exporting to file and domNode

%%
% 
febioAnalysis.run_filename=febioFebFileName; %The input file name
febioAnalysis.run_logname=febioLogFileName; %The name for the log file
febioAnalysis.disp_on=1; %Display information on the command window
febioAnalysis.runMode='internal';%'internal';

[runFlag]=runMonitorFEBio(febioAnalysis);%START FEBio NOW!!!!!!!!