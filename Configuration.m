classdef Configuration < handle

  properties ( Access=public)
  end

  properties ( Access=private)
    parent
    fig
    labels
    buttons
    add_button
    remove_button
    save_button
    cancel_button
    box_height = 30
    font_size = 16
  end

  methods ( Access=public)

    function obj = Configuration( parameters, parent)
      obj.fig = obj.makeFigure();
      if nargin > 0
        obj.parent = parent;
        obj.font_size = obj.parent.font_size;
        obj.resizeFont( 'TextBox');
        obj.addButtons( parameters);
      else
        obj.addButtons();
      end
    end

    function delete( obj)
      delete( obj.fig);
    end
  end
  
  methods ( Access = ?Settings)
    function setFontsize( obj, fontsize)
      obj.font_size = fontsize;
      obj.resizeFont( 'uicontrol');
      obj.resizeFont( 'TextBox');
    end
  end

  methods ( Access=private)

    function fig = makeFigure( obj)

      fig_height = 150;

      fig = figure( 'Position', [800, 400, 420, fig_height], ...
                    'Name', 'Configuration', ...
                    'NumberTitle', 'off', ...
                    'Resize', 'off', ...
                    'Menubar', 'None', ...
                    'Toolbar', 'None'); ...
                    %'CloseRequestFcn', @(~,~) obj.delete());

      obj.labels = gobjects( 1, 4);

      obj.labels(1) = annotation( fig, ...
                'Textbox', 'String', 'Name', ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [20 fig_height-40 80 obj.box_height], ...
                'Interpreter', 'None', ...
                'Visible', 'on');

      obj.labels(2) = annotation( fig, ...
                'Textbox', 'String', 'Value', ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [120 fig_height-40 80 obj.box_height], ...
                'Interpreter', 'None', ...
                'Visible', 'on');

      obj.labels(3) = annotation( fig, ...
                'Textbox', 'String', 'Min.', ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [220 fig_height-40 80 obj.box_height], ...
                'Interpreter', 'None', ...
                'Visible', 'on');

      obj.labels(4) = annotation( fig, ...
                'Textbox', 'String', 'Max.', ...
                'Fontsize', obj.font_size, ...
                'Units', 'pixels', ...
                'Position', [320 fig_height-40 80 obj.box_height], ...
                'Interpreter', 'None', ...
                'Visible', 'on');

    end
    
    function resizeFont( obj, type)
      handles = findall( obj.fig, 'Type', type);
      for handle = handles
        set( handle, 'Fontsize', obj.font_size);
      end
    end

    function shiftY( ~, obj, shift)
      pos = get( obj, 'Position');
      pos(2) = pos(2) + shift;
      set( obj, 'Position', pos);
    end

    function shiftHeight( ~, obj, shift)
      pos = get( obj, 'Position');
      pos(4) = pos(4) + shift;
      set( obj, 'Position', pos);
    end

    function height = getHeight( ~, obj)
      pos = get( obj, 'Position');
      height = pos(4);
    end

    function shiftFigure( obj, shift)

      obj.shiftY( obj.fig, -shift);
      obj.shiftHeight( obj.fig, shift);

      no_rows = size( obj.buttons, 1);

      for lab_no = 1:4
        obj.shiftY( obj.labels(lab_no), shift);
      end

      for row_no = 1:no_rows
        for box_no = 1:4
          obj.shiftY( obj.buttons(row_no,box_no), shift);
        end
      end
    end

    function addRow( obj)

      no_rows = size( obj.buttons, 1);
      obj.shiftFigure( obj.box_height);

      fig_height = obj.getHeight( obj.fig);

      for but_no = 1:4
        obj.buttons(no_rows+1,but_no) = uicontrol( 'Parent', obj.fig, ...
                 'Style', 'edit', ...
                 'String', '', ...
                 'Units', 'pixels', ...
                 'Position', [20+(but_no-1)*100 fig_height-80-no_rows*obj.box_height 80 obj.box_height], ...
                 'Visible', 'on', ...
                 'Fontsize', obj.font_size);
      end

      for but_no = 2:4
        obj.buttons(no_rows+1,but_no).Callback = @(src,~) obj.checkValue( src);
      end

    end

    function removeRow( obj)

      no_rows = size( obj.buttons, 1);

      if no_rows > 1

        delete( obj.buttons( no_rows, :));
        obj.buttons(no_rows,:) = [];

        obj.shiftFigure( -obj.box_height);

      end

    end

    function addButtons( obj, parameters)
      
      if (nargin > 1) && (length( parameters)>1)
        
        no_pars = length( parameters);
        obj.buttons = gobjects( no_pars, 4);
        
        fig_height = 150;
        
        for par_no = 1:no_pars
          obj.buttons(par_no,1) = uicontrol( 'Parent', obj.fig, ...
            'Style', 'edit', ...
            'String', parameters(par_no).name, ...
            'Units', 'pixels', ...
            'Position', [20 fig_height-80-(par_no-1)*obj.box_height 80 obj.box_height], ...
            'Visible', 'on', ...
            'Fontsize', obj.font_size);
          
          obj.buttons(par_no,2) = uicontrol( 'Parent', obj.fig, ...
            'Style', 'edit', ...
            'String', parameters(par_no).val, ...
            'Units', 'pixels', ...
            'Position', [120 fig_height-80-(par_no-1)*obj.box_height 80 obj.box_height], ...
            'Visible', 'on', ...
            'Fontsize', obj.font_size);
          
          obj.buttons(par_no,3) = uicontrol( 'Parent', obj.fig, ...
            'Style', 'edit', ...
            'String', parameters(par_no).min, ...
            'Units', 'pixels', ...
            'Position', [220 fig_height-80-(par_no-1)*obj.box_height 80 obj.box_height], ...
            'Visible', 'on', ...
            'Fontsize', obj.font_size);
          
          obj.buttons(par_no,4) = uicontrol( 'Parent', obj.fig, ...
            'Style', 'edit', ...
            'String', parameters(par_no).max, ...
            'Units', 'pixels', ...
            'Position', [320 fig_height-80-(par_no-1)*obj.box_height 80 obj.box_height], ...
            'Visible', 'on', ...
            'Fontsize', obj.font_size);
          
        end
        
        obj.shiftFigure( (no_pars-1)*obj.box_height);
        
      else
        
        fig_height = obj.getHeight( obj.fig);
        obj.buttons = gobjects( 1, 4);
        
        for but_no = 1:4
          obj.buttons(1,but_no) = uicontrol( 'Parent', obj.fig, ...
            'Style', 'edit', ...
            'String', '', ...
            'Units', 'pixels', ...
            'Position', [20+(but_no-1)*100 fig_height-80 80 obj.box_height], ...
            'Visible', 'on', ...
            'Fontsize', obj.font_size);
          
        end
        
      end

      for par_no = 1:size( obj.buttons, 1)
        for but_no = 2:4
          obj.buttons(par_no,but_no).Callback = @(src,~) obj.checkValue( src);
        end
      end

      obj.add_button = uicontrol( 'Parent', obj.fig, ...
             'Style', 'pushbutton', ...
             'String', '+', 'Units', 'pixels', ...
             'Position', [60 20 40 40], 'Visible', 'on', ...
             'Fontsize', 30, ...
             'Tag', 'zero','Callback', @(~,~) obj.addRow());

      obj.remove_button = uicontrol( 'Parent', obj.fig, ...
             'Style', 'pushbutton', ...
             'String', '-', 'Units', 'pixels', ...
             'Position', [100 20 40 40], 'Visible', 'on', ...
             'Fontsize', 30, ...
             'Tag', 'zero','Callback', @(~,~) obj.removeRow());

      obj.save_button = uicontrol( 'Parent', obj.fig, ...
             'Style', 'pushbutton', ...
             'String', 'Save', 'Units', 'pixels', ...
             'Position', [210 20 80 40], 'Visible', 'on', ...
             'Fontsize', obj.font_size, ...
             'Tag', 'zero','Callback', @(~,~) obj.savePars());

      obj.cancel_button = uicontrol( 'Parent', obj.fig, ...
             'Style', 'pushbutton', ...
             'String', 'Cancel', 'Units', 'pixels', ...
             'Position', [290 20 80 40], 'Visible', 'on', ...
             'Fontsize', obj.font_size, ...
             'Tag', 'zero','Callback', @(~,~) obj.delete());
    end

    function valid_flag = checkBoxes( obj)
      valid_flag = true;
      for but_no = 1:numel( obj.buttons)
        if isempty( obj.buttons(but_no).String)
          valid_flag = false;
          wrn = warndlg( 'One or more values have not been set');
          obj.resizeDialogBox( wrn, 400);
          break;
        end
      end
    end

    function savePars( obj)

      if obj.checkBoxes()
        for par_no = 1:size( obj.buttons, 1)
          parameters(par_no).name = obj.buttons(par_no,1).String;
          parameters(par_no).val  = str2double( obj.buttons(par_no,2).String);
          parameters(par_no).min  = str2double( obj.buttons(par_no,3).String);
          parameters(par_no).max  = str2double( obj.buttons(par_no,4).String);
        end

        [filename,pathname] = uiputfile( '*.mat');
        filename = strcat( pathname, filename);
        save( filename, 'parameters');

        if ~isempty( obj.parent)
          obj.parent.loadPars( filename);
        end
        obj.delete();
      end

    end

    function checkValue( obj, src)
      str = get( src, 'String');
      if isnan( str2double( str))
        src.String = '0';
        wrn = warndlg( 'Input must be numerical');
        obj.resizeDialogBox( wrn, 280);
      end
    end
    
    function resizeDialogBox( ~, obj, width)
      htext = findobj( obj, 'Type', 'Text');
      set( htext, 'Fontsize', 16);
      pos = get( obj, 'Position');
      pos(3) = width;
      set( obj, 'Position', pos);
    end

  end

end
