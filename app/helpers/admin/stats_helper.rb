module Admin
  module StatsHelper
    # Renders a responsive SVG line chart of plays and downloads over time.
    # +series+ is StatsReport#daily_series output. Pure server-side SVG, no JS.
    def daily_chart_svg(series, max_value:)
      return ''.html_safe if series.empty?

      width = 920
      height = 220
      pad_left = 38
      pad_right = 8
      pad_top = 12
      pad_bottom = 26
      inner_w = width - pad_left - pad_right
      inner_h = height - pad_top - pad_bottom
      max = [max_value, 1].max
      step_x = series.length > 1 ? inner_w.to_f / (series.length - 1) : 0

      y_for = ->(value) { pad_top + inner_h - (value.to_f / max * inner_h) }
      x_for = ->(index) { pad_left + index * step_x }

      points = lambda do |field|
        series.each_with_index.map { |row, i| "#{x_for[i].round(1)},#{y_for[row[field]].round(1)}" }.join(' ')
      end

      grid_lines = (0..3).map do |i|
        y = pad_top + (inner_h * i / 3.0)
        value = (max * (3 - i) / 3.0).round
        tag.line(x1: pad_left, y1: y.round(1), x2: width - pad_right, y2: y.round(1), class: 'stats-chart-grid') +
          tag.text(value, x: pad_left - 6, y: (y + 4).round(1), class: 'stats-chart-y-label', 'text-anchor': 'end')
      end

      x_labels = [0, series.length / 2, series.length - 1].uniq.map do |i|
        tag.text(series[i][:label], x: x_for[i].round(1), y: height - 8, class: 'stats-chart-x-label',
                                    'text-anchor': if i.zero?
                                                     'start'
                                                   else
                                                     (i == series.length - 1 ? 'end' : 'middle')
                                                   end)
      end

      tag.svg(viewBox: "0 0 #{width} #{height}", class: 'stats-chart', role: 'img',
              'aria-label': t('admin.stats.chart_aria')) do
        safe_join(grid_lines) +
          tag.polyline(points: points[:downloads], class: 'stats-chart-line stats-chart-line-downloads', fill: 'none') +
          tag.polyline(points: points[:plays], class: 'stats-chart-line stats-chart-line-plays', fill: 'none') +
          safe_join(x_labels)
      end
    end

    # Column header link for the sortable tables. Toggles direction when the
    # column is already active; resets pagination. +prefix+ is '' for the
    # tracks table and 'd' for the downloads table (param names stay sort/dir/page
    # vs dsort/ddir/dpage).
    def stats_sort_link(label, column, report:, prefix:, extra_params: {})
      current_sort = prefix.empty? ? report.sort : report.dsort
      current_dir = prefix.empty? ? report.dir : report.ddir
      active = current_sort == column
      new_dir = active && current_dir == 'desc' ? 'asc' : 'desc'

      params_key = ->(name) { "#{prefix}#{name}" }
      query = request.query_parameters.merge(
        'range' => report.range,
        params_key['sort'] => column,
        params_key['dir'] => new_dir,
        params_key['page'] => 1
      ).merge(extra_params)

      # Fixed-width arrow slot: always rendered (empty when inactive) so the
      # header's natural width — and thus the column widths — stay stable.
      arrow = if active
                current_dir == 'desc' ? '↓' : '↑'
              else
                ''
              end
      link_to admin_stats_path(query),
              class: ['stats-sort', ('is-active' if active)].compact.join(' '),
              data: { turbo_stream: true, turbo_prefetch: false } do
        safe_join([
                    tag.span(label, class: 'stats-sort-label'),
                    tag.span(arrow, class: 'stats-sort-arrow', 'aria-hidden': 'true')
                  ])
      end
    end
  end
end
