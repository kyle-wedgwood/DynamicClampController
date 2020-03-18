classdef DynamicClampController < handle

  properties ( Access = private)

    COMPort
    parameters
    fig
    buttons
    min_labels
    name_labels
    max_labels
    save_button
    load_button
    configure_button
    preferences_button
    last_button
    zero_button
    upload_button
    box_height = 30
    box_width = 90
    status_bar
    timer
    PRC_filename
    wave_filename
    PRC_harmonics
    wave
    load_PRC_button
    load_wave_button
    PRC_file_display
    wave_file_display

  end

  properties ( Access = {?Configuration, ?Preferences})
    font_size = 16
  end
  
  properties ( Access= ?Preferences)
    config
  end

  methods ( Access = ?Preferences)
    
    function setFontsize( obj, fontsize)
      obj.font_size = fontsize;
      obj.resizeFont( 'uicontrol');
      obj.resizeFont( 'TextBox');
    end
    
  end
  
  methods ( Access = public)
    
    function obj = DynamicClampController( filename)

      obj.initialiseCOMPort();
      if nargin < 1
        filename = 'last_used_pars.mat';
      end
      
      if exist( filename, 'file')
        parameters = load( filename);
        obj.parameters = parameters.parameters;
      else
        obj.parameters = struct( 'name', {}, 'val', {}, ...
                                 'min', {}, 'max', {});
      end

      % Load preferences if they exist
      obj.loadPreferences();
      
      obj.fig = obj.makeFigure();
      obj.create_timer();
      obj.update_status_bar( 'Successfully connected to Teensy');

    end

    function delete( obj)

      delete( obj.timer);
      fclose( obj.COMPort);
      fprintf( 'COM port closed.\n');

      delete( obj.fig);

      fprintf( 'Dynamic clamp controller exited successfully.\n');

    end

    function setVal( obj, name, val)

      ind = obj.findValIndex( name);

      if ~isempty( ind)
        obj.parameters(ind).val = val;
      else
        fprintf( 'Parameter not found.\n');
      end
    end

    function val = getVal( obj, name)

      ind = obj.findValIndex( name);

      if ~isempty( ind)
        val = obj.parameters(ind).val;
      else
        fprintf( 'Parameter not found.\n');
      end
    end
    
    function vals = getAllVals( obj)
      vals = [obj.parameters.val]';
    end

    function printVals( obj)

      disp( struct2table( obj.parameters));

    end

  end
  
  methods ( Access = ?Configuration)
    
    function loadPars( obj, filename)
      if nargin < 2
        filename = uigetfile( '*.mat');
      end
      
      if exist( filename, 'file')
        obj.update_status_bar( sprintf( 'Loading parameters from %s.\n', filename));
        obj.parameters = load( filename);
        obj.parameters = obj.parameters.parameters;
        
        obj.removeButtons();
        obj.resizeFigure();
        obj.addButtons( obj.fig);
        
        fclose( obj.COMPort);
        obj.initialiseCOMPort();
      else
        wrn = warndlg( 'File not found');
        htext = findobj( wrn, 'Type', 'Text');  %find text control in dialog
        htext.FontSize = obj.font_size;
      end
      
    end
    
  end

  methods ( Access = private)

    function initialiseCOMPort( obj)

      obj.COMPort = serial( 'COM14', 'BaudRate', 115200);
      fopen ( obj.COMPort);

      fprintf( 'COM port opened.\n');

    end

    function writeToTeensy( obj)

      vals = single( vertcat( obj.parameters.val, []));
      
      % Add PRC harmonic and wave
      vals = [vals; obj.PRC_harmonics(:,1); obj.wave(:,2)];

      fwrite( obj.COMPort, typecast( vals, 'uint8'));
      obj.update_status_bar( 'Values sent to Teensy');

    end

    function vals = readFromTeensy( obj)

      no_pars = length( obj.parameters);
      vals = zeros( no_pars, 1);
      
      for par_no = 1:no_pars
        vals(par_no) = fscanf( obj.COMPort, '%f');
      end
      
    end

    function fig = makeFigure( obj)

      no_pars = length( obj.parameters);
      fig_height = (no_pars+5)*50;

      fig = figure( 'Position', [400, 400, 400, fig_height], ...
                    'Name', 'DynamicClampController', ...
                    'NumberTitle', 'off', ...
                    'Resize', 'off', ...
                    'Menubar', 'None', ...
                    'Toolbar', 'None', ...
                    'CloseRequestFcn', @(~,~) obj.delete());
      
      obj.addButtons( fig);
      
    end
    
    function ind = findValIndex( obj, name)
      ind = find( strcmp( {obj.parameters.name}, name));
    end

    function setValUI( obj, src, ~)
      old_val = obj.getVal( src.Tag);
      val = str2double( src.String);
      ind = obj.findValIndex( src.Tag);
      max_val = obj.parameters(ind).max;
      min_val = obj.parameters(ind).min;
      if isnan( val)
        err = errordlg( sprintf( '%s must be a number', src.Tag));
        src.String = num2str( old_val);
        obj.resizeDialogBox( err, 300);
      elseif val > max_val
        err = errordlg( sprintf( '%s must be less than %.1f', src.Tag, max_val));
        src.String = max_val;
        obj.resizeDialogBox( err, 350);
      elseif val < min_val
        err = errordlg( sprintf( '%s must be greater than %.1f', src.Tag, min_val));
        src.String = min_val;
        obj.resizeDialogBox( err, 350);
      else
        obj.setVal( src.Tag, str2double( src.String));
      end
    end
    
    function resizeDialogBox( obj, warn_box, width)
      htext = findobj( warn_box, 'Type', 'Text');
      set( htext, 'Fontsize', obj.font_size);
      pos = get( warn_box, 'Position');
      pos(3) = width;
      set( warn_box, 'Position', pos);
    end

    function zeroValsUI( obj)
      for par_no = 1:length( obj.buttons)
        obj.buttons(par_no).String = 0.0;
        obj.setVal( obj.buttons(par_no).Tag, 0.0);
      end
      obj.uploadVals( false);
    end
    
    function synchronised_flag = checkSynchronised( obj)
      synchronised_flag = false;
      teensy_vals = obj.readFromTeensy();
      vals = obj.getAllVals();
      if all( vals==teensy_vals)
        synchronised_flag = true;
        obj.update_status_bar( 'Values sent successfully.');
      else
        obj.update_status_bar( 'Values not synchronised... Resending.');
      end
    end

    function uploadVals( obj, save_flag)
      obj.update_status_bar( 'Uploading values');
      
      if obj.checkFilesLoaded()
        if save_flag
          obj.savePars( false);
        end

        synchronised = false;
        while ~synchronised
          obj.writeToTeensy();
          synchronised = obj.checkSynchronised();
        end
      else
        obj.update_status_bar( 'Aboring upload')
      end
      
    end

    function removeButtons( obj)
      delete( obj.min_labels);
      delete( obj.name_labels);
      delete( obj.max_labels);
      delete( obj.buttons);
      obj.min_labels(:) = [];
      obj.name_labels(:) = [];
      obj.max_labels(:) = [];
      obj.buttons(:) = [];
    end
    
    function loadPRC( obj)
      
      [filename,pathname] = uigetfile( '*');
      full_path = strcat( pathname, filename);
      
      if exist( full_path, 'file')
        obj.PRC_harmonics = single( load( full_path));
        obj.PRC_filename = filename;
        set( obj.PRC_file_display, 'String', filename);
        obj.update_status_bar( 'PRC harmonics loaded from filename');
      else
        wrn = warndlg( 'File not found');
        htext = findobj( wrn, 'Type', 'Text');  %find text control in dialog
        htext.FontSize = obj.font_size;
      end
      
      if size( obj.PRC_harmonics, 2) > 1
        wrn = warndlg( '> 1 column in file');
        htext = findobj( wrn, 'Type', 'Text');  %find text control in dialog
        htext.FontSize = obj.font_size;
      end
      
    end
    
    function loadWave( obj)
      
      [filename,pathname] = uigetfile( '*');
      full_path = strcat( pathname, filename);
      
      if exist( full_path, 'file')
        obj.wave = single( load( full_path));
        obj.wave_filename = filename;
        set( obj.wave_file_display, 'String', filename);
        obj.update_status_bar( 'Wave data loaded from filename');
      else
        wrn = warndlg( 'File not found');
        htext = findobj( wrn, 'Type', 'Text');  %find text control in dialog
        htext.FontSize = obj.font_size;
      end
      
      if size( obj.wave, 2) > 1
        wrn = warndlg( '> 1 column in file');
        htext = findobj( wrn, 'Type', 'Text');  %find text control in dialog
        htext.FontSize = obj.font_size;
      end
      
    end
    
    function flag = checkFilesLoaded( obj)
      
      flag = false;
      
      if ~( isempty( obj.PRC_harmonics) || isempty( obj.wave))
        flag = true;
      else
        if isempty( obj.PRC_harmonics);
          wrn = warndlg( 'PRC not loaded');
        elseif isempty( obj.wave);
          wrn = warndlg( 'Wave data not loaded');
        end
        htext = findobj( wrn, 'Type', 'Text');  %find text control in dialog
        htext.FontSize = obj.font_size;
      end
      
    end
    
    function savePars( obj, input_flag)

      if input_flag
        [filename,pathname] = uiputfile( '*.mat');
        filename = strcat( pathname, filename);
      else
        filename = 'last_used_pars.mat';
      end

      parameters = obj.parameters;

      save( filename, 'parameters');

      obj.update_status_bar( sprintf( 'Saved parameters to %s.', filename));
    end
    
    function resizeFigure( obj)
      
      no_pars = length( obj.parameters);
      fig_height = (no_pars+10)*50;
      
      pos = get( obj.fig, 'Position');
      pos(4) = fig_height;
      set( obj.fig, 'Position', pos);
      
    end

    function configure( obj)
      obj.config = Configuration( obj.parameters, obj);
    end
    
    function openPreferences( obj)
      Preferences( obj);
    end
    
    function resizeFont( obj, type)
      handles = findall( obj.fig, 'Type', type);
      for handle = handles
        set( handle, 'Fontsize', obj.font_size);
      end
    end
    
    function loadPreferences( obj)
      filename = 'preferences.mat';
      if exist( filename, 'file')
        temp = load( filename);
        preferences = temp.preferences;
        ind = find( strcmp( 'Fontsize', {preferences.name}));
        if ~isempty( ind)
          obj.font_size = preferences(ind).val;
        end
      end
      
    end

    function addButtons( obj, fig)

      no_pars = length( obj.parameters);
      fig_height = (no_pars+9)*obj.box_height;
      set( fig, 'Position', [400, 400, 400, fig_height]);

      obj.buttons = gobjects( no_pars, 1);
      obj.name_labels = gobjects( no_pars, 1);

      for par_no = 1:no_pars
        
        obj.name_labels(par_no) = annotation( fig, ...
                'Textbox', 'String', obj.parameters(par_no).name, ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [20 fig_height-obj.box_height*(par_no+1) obj.box_width obj.box_height], ...
                'Interpreter', 'None', ...
                'Visible', 'on');
              
        obj.min_labels(par_no) = annotation( fig, ...
                'Textbox', 'String', obj.parameters(par_no).min, ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [120 fig_height-obj.box_height*(par_no+1) obj.box_width obj.box_height], ...
                'Interpreter', 'None', ...
                'HorizontalAlignment', 'center', ...
                'Visible', 'on');

        obj.buttons(par_no) = uicontrol( 'Parent', fig, ...
                 'Style', 'edit', ...
                 'String', obj.parameters(par_no).val, ...
                 'Units', 'pixels', ...
                 'Position', [210 fig_height-obj.box_height*(par_no+1) obj.box_width obj.box_height], ...
                 'Visible', 'on', ...
                 'Tag', obj.parameters(par_no).name, ...
                 'Fontsize', obj.font_size, ...
                 'Callback', @obj.setValUI);
               
        obj.max_labels(par_no) = annotation( fig, ...
                'Textbox', 'String', obj.parameters(par_no).max, ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [300 fig_height-obj.box_height*(par_no+1) obj.box_width obj.box_height], ...
                'Interpreter', 'None', ...
                'HorizontalAlignment', 'center', ...
                'Visible', 'on');

      end
      
      obj.load_PRC_button = uicontrol( 'Parent', fig, 'Style', 'togglebutton', ...
             'String', 'PRC file', 'Units', 'pixels', ...
             'Position', [20 190 100 30], 'Visible', 'on', ...
             'Fontsize', obj.font_size,  'ForegroundColor', 'red', ...
             'Tag', 'loadPRC','Callback', @(~,~) obj.loadPRC());
           
      obj.PRC_file_display = uicontrol( 'Parent', fig, 'Style', 'text', ...
             'String', obj.PRC_filename, 'Units', 'pixels', ...
             'Position', [120 190 270 30], 'Visible', 'on', ...
             'Fontsize', obj.font_size);
           
      obj.load_wave_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Wave file', 'Units', 'pixels', ...
             'Position', [20 160 100 30], 'Visible', 'on', ...
             'Fontsize', obj.font_size,  'ForegroundColor', 'red', ...
             'Tag', 'loadWave','Callback', @(~,~) obj.loadWave());
           
      obj.wave_file_display = uicontrol( 'Parent', fig, 'Style', 'text', ...
             'String', obj.wave_filename, 'Units', 'pixels', ...
             'Position', [120 160 270 30], 'Visible', 'on', ...
             'Fontsize', obj.font_size, ...
             'Tag', 'zero','Callback', @(~,~) obj.zeroValsUI());

      obj.zero_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Zero', 'Units', 'pixels', ...
             'Position', [250 50 100 50], 'Visible', 'on', ...
             'Fontsize', obj.font_size, ...
             'Tag', 'zero','Callback', @(~,~) obj.zeroValsUI());

      obj.upload_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Upload', 'Units', 'pixels', ...
             'Fontsize', obj.font_size, ...
             'Position', [50 50 100 50], 'Visible', 'on', ...
             'Tag', 'zero', 'Callback', @(~,~) obj.uploadVals( true));

      obj.load_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Load', 'Units', 'pixels', ...
             'Fontsize', obj.font_size, ...
             'Position', [50 100 100 50], 'Visible', 'on', ...
             'Tag', 'zero', 'Callback', @(~,~) obj.loadPars());

      obj.last_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Last', 'Units', 'pixels', ...
             'Fontsize', obj.font_size, ...
             'Position', [150 50 100 50], 'Visible', 'on', ...
             'Tag', 'zero', 'Callback', @(~,~) obj.loadPars( 'last_used_pars.mat'));

      obj.configure_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Configure', 'Units', 'pixels', ...
             'Fontsize', obj.font_size, ...
             'Position', [150 100 100 50], 'Visible', 'on', ...
             'Tag', 'zero', 'Callback', @(~,~) obj.configure());

      obj.save_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'String', 'Save', 'Units', 'pixels', ...
             'Fontsize', obj.font_size, ...
             'Position', [250 100 100 50], 'Visible', 'on', ...
             'Tag', 'zero', 'Callback', @(~,~)obj.savePars( true));
           
      obj.status_bar = uicontrol( 'Parent', fig, 'Style', 'text', ...
              'String', '', 'Units', 'pixels', ...
              'Fontsize', 0.8*obj.font_size, ...
              'Position', [15, 5, 350, 30], 'Visible', 'on', ...
              'HorizontalAlignment', 'left');
            
      
      % Update color of load buttons if data are already loaded
      if ~isempty( obj.PRC_harmonics)
        set( obj.load_PRC_button, 'ForegroundColor', 'black');
      end
      if ~isempty( obj.wave)
        set( obj.load_wave_button, 'ForegroundColor', 'black');
      end
           
      im = imread( 'settings.png');
      [im_width,im_height,~]=size( im); 
      delta_x = ceil( im_width/30); 
      delta_y = ceil( im_height/30); 
      im = im(1:delta_x:end,1:delta_y:end,:);
           
      obj.preferences_button = uicontrol( 'Parent', fig, 'Style', 'pushbutton', ...
             'Units', 'pixels', 'Position', [360 10 30 30], ...
             'CData', (1-im)*225, 'Visible', 'on', ...
             'Tag', 'zero', 'Callback', @(~,~) obj.openPreferences());
           

    end
    
    function create_timer( obj)
      obj.timer = timer( 'StartDelay', 2, 'ExecutionMode', 'singleShot', ...
              'TimerFcn', @(~,~) obj.reset_status_bar());
    end
    
    function update_status_bar( obj, message)
      set( obj.status_bar, 'String', message);
      if strcmp( get( obj.timer, 'Running'), 'on')
        stop( obj.timer)
      end
      start( obj.timer);
    end
    
    function reset_status_bar( obj)
% For testing purposes only
%       for i = 1:4
%         val_0 = fscanf( obj.COMPort, '%f');
%         val_1 = fscanf( obj.COMPort, '%d');
%         val_2 = fscanf( obj.COMPort, '%d');
%         val_3 = fscanf( obj.COMPort, '%f');
%         set( obj.status_bar, 'String', sprintf( '%d, delay: %0.3f, dt: %.3f ms, i_c: %d, i_d: %d', i, val_0, val_3, val_1, val_2));
%         pause(1);
%       end
      set( obj.status_bar, 'String', 'Ready');
    end

  end

end
