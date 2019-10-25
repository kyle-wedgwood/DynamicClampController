classdef Preferences < handle
  
  properties ( Access = private)
    parent
    fig
    box_width = 80
    box_height = 30
    preferences
    preference_names = {'Fontsize'}
    preference_vals
    font_size
    labels
    buttons
  end
  
  methods ( Access = public)
    
    function obj = Preferences( parent)
      
      obj.parent = parent;
      obj.font_size = obj.parent.font_size;
      obj.preference_vals = obj.font_size;
      funs = { @obj.changeFontsize};
      
      for preference_no = 1:length( obj.preference_names)
        obj.preferences(preference_no).name = obj.preference_names{preference_no};
        obj.preferences(preference_no).val  = obj.preference_vals(preference_no);
        obj.preferences(preference_no).fun  = funs{preference_no};
      end
      
      obj.fig = obj.makeFigure();
      
    end
    
    function delete( obj)
      delete( obj.fig);
    end
    
  end
  
  methods ( Access = private)
    
    function fig = makeFigure( obj)
      
      fig_height = obj.box_height*( length( obj.preference_names) + 2);
      
      fig = figure( 'Position', [400, 500, 200, fig_height], ...
                    'Name', 'Preferences', ...
                    'NumberTitle', 'off', ...
                    'Resize', 'off', ...
                    'Menubar', 'None', ...
                    'Toolbar', 'None');
      
      obj.addButtons( fig);
      
    end
    
    function addButtons( obj, fig)
      fig_height = obj.getHeight( fig);
      no_preferences = length( obj.preference_names);
      obj.buttons = gobjects( no_preferences, 1);
      obj.labels  = gobjects( no_preferences, 1);
      for preference_no = 1:length( obj.preference_names)
        obj.labels(preference_no) = annotation( fig, ...
                'Textbox', 'String', obj.preferences(preference_no).name, ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [20 fig_height-obj.box_height*(preference_no+1) obj.box_width obj.box_height], ...
                'Interpreter', 'None', ...
                'Visible', 'on');
              
         obj.buttons(preference_no) = uicontrol( 'Parent', fig, ...
                 'Style', 'edit', ...
                 'String', obj.preferences(preference_no).val, ...
                 'Units', 'pixels', ...
                 'Position', [30+obj.box_width fig_height-obj.box_height*(preference_no+1) obj.box_width obj.box_height], ...
                 'Visible', 'on', ...
                 'Tag', obj.preference_names{preference_no}, ...
                 'Fontsize', obj.font_size, ...
                 'Callback', obj.preferences(preference_no).fun);
      end
    end
    
    function val = getVal( obj, name)

      ind = find( strcmp( { obj.preferences.name}, name));

      if ~isempty( ind)
        val = obj.preferences(ind).val;
      else
        fprintf( 'Setting not found.\n');
      end
    end
    
    function changeFontsize( obj, src, ~)
      old_val = obj.getVal( src.Tag);
      val = str2double( src.String);
      if isnan( val)
        err = errordlg( sprintf( '%s must be a number', src.Tag));
        src.String = num2str( old_val);
        obj.resizeDialogBox( err, 300);
      else
        obj.setFontsize( val);
      end
      
      ind = obj.findPreference( 'Fontsize');
      obj.preferences(ind).val = val;
      preferences = rmfield( obj.preferences, 'fun');
      save( 'preferences.mat', 'preferences');
      
    end
    
    function resizeFont( obj, type)
      handles = findall( obj.fig, 'Type', type);
      for handle = handles
        set( handle, 'Fontsize', obj.font_size);
      end
    end
    
    function setFontsize( obj, fontsize)
      obj.font_size = fontsize;
      obj.resizeFont( 'uicontrol');
      obj.resizeFont( 'TextBox');

      obj.parent.setFontsize( fontsize);
      if ~isempty( obj.parent.config)
        obj.parent.config.setFontsize( fontsize);
      end
    end
    
    function height = getHeight( ~, obj)
      pos = get( obj, 'Position');
      height = pos(4);
    end
    
    function ind = findPreference( obj, name)
      
      ind = find( strcmp({obj.preferences.name}, name));
      
    end
    
  end
  
end