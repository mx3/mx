/*   Simple sortable table plugin
 *
 *   Add data-sortable-table to the table, and it will add arrows and some classes.
 *
 *   Make sure to define some CSS for 'sorted-column' to show which column is being sorted by.
 *
 *   the configuration is put on the th elements.
 *
 *   data-sortable-initial  : the initial column to sort on (defaults to first one);
 *   data-sortable-by       : what to sort the column with, currently alpha or integer
 *   data-sortable-skip     : to skip sorting this column

  EXAMPLE:
    <style>
      table[data-sortable-table] .sorted-column { background: #efefef; }
      table[data-sortable-table] th.sorted-column { background: #b6b6b6; color: #333; }
      table[data-sortable-table] th { cursor: pointer; }
      table[data-sortable-table] th[data-sortable-skip] { cursor: default; }
    </style>
    <table data-sortable-table>
      <tr>
        <th                       data-sortable-by='alpha'>  Alpha</th>
        <th data-sortable-initial data-sortable-by='integer'>Integer</th>
        <th data-sortable-skip=true                         >Skip</th>
      </tr>
      <tr>
        <td>a</td>
        <td>3</td>
        <td>skip</td>
      </tr>
      <tr>
        <td>b</td>
        <td>2</td>
        <td>skip</td>
      </tr>
      <tr>
        <td>c</td>
        <td>1</td>
        <td>skip</td>
      </tr>
    </table>
 *
 */
(function ($) {
  $.fn.mx_sortable_table = function() {

    if (!this.length) {   return this; }
    var options = {
      unselected_up:    '&#9651;',
      selected_up:      '&#9650;',
      unselected_down:  '&#9661;',
      selected_down:    '&#9660;',
      // Each TH has a direction -
      // null -- no selection means it'll be unselected down arrow
      // up
      // down
      render_header: function($table) {
        $table.find("tr > th").each(function(i, th) {
          var $th = $(th);
          if (!$th.data('sortableSkip')) {
            var direction = $th.data('sortableDirection');
            var icon = $th.data('sortableControl');

            /// Create it if it's not there already
            if (!icon) {
              icon = $("<span class='sortable-controls'>");
              $th.append(icon);
              $th.data('sortableControl', icon);
            }

            if (direction === 'up') {
              icon.html(options.selected_up);
            } else if (direction === 'down') {
              icon.html(options.selected_down);
            } else {
              icon.html(options.unselected_up);
            }
          }
        });
      },
      toggle_header: function(table, th) {
        var $th = $(th);
        var $table = $(table);
        var cur_state = $th.data('sortableDirection');

        // Clear them all out
        $table.find("tr > th").each(function(i, th) { $(th).data('sortableDirection', null); });

        // Clicking will set this one to new state
        if (cur_state === 'up') {
          $th.data('sortableDirection', 'down');
        } else if (cur_state === 'down') {
          $th.data('sortableDirection', 'up');
        } else {
          $th.data('sortableDirection', 'up');
        }
      },
      render_table: function(table, active_th) {
        var headers = $("tr > th");
        var column_index = 0;

        headers.each(function(i, th) {
          console.log(th, active_th);
          if (th === active_th.get(0)) { column_index = i; }
        });

        $(table).find(".sorted-column").removeClass('sorted-column');

        active_th.addClass('sorted-column');

        var columns_to_sort = $(table).find("tr td:nth-child("+(column_index+1)+")");
        var sort_type = active_th.data('sortableBy');
        var sort_direction = active_th.data('sortableDirection');

        var sorted_rows = columns_to_sort.sort(function(a,b) {
            var result = 0;
            var $a = $(a);
            var $b = $(b);
            if (sort_type === 'integer') {
              result = parseInt($a.html(), 10) > parseInt($(b).html(), 10) ? 1 : -1;
            } else {
              result = $a.html().toLowerCase() > $b.html().toLowerCase() ? 1 : -1;
            }

            if (sort_direction === 'up') {
              return result;
            } else {
              return result * -1;
            }
        })
        .each(function(i, td) {
          $(td).addClass('sorted-column');
        })
        .map(function(i, col) {
          console.log('col', col);
          return $(col).closest('tr');
        });

        var prev_row = null;
        sorted_rows.each(function(i, row) {
          if (prev_row) {
            prev_row.after(row);
          }
          prev_row = $(row);
        });
      }
    };
    return this.each(function() {
      var $table = $(this);
      var active_th = $("tr > th[data-sortable-initial]").first();

      if (active_th.size() === 0) {
       active_th = $("tr > th:first-child").first();
      }

      // Intitially toggle
      options.toggle_header($table, active_th);
      options.render_header($table);
      options.render_table($table, active_th);

      $table.delegate('tr > th','click', function(e) {
        var th = null;
        if ($(e.srcElement).is("th")) {
          th = $(e.srcElement);
        } else {
          th = $(e.srcElement).closest('th');
        }

        if (!$(th).data('sortableSkip')) {
          active_th = th;
          options.toggle_header($table, active_th);
          options.render_header($table);

          options.render_table($table, active_th);
        }
      });
    });
  };
})(jQuery);
