// See https://datatables.net/usage/server-side
global class DataTableController {
 
    // Defines shape of JSON response
    global class Response {
        public Integer sEcho;
        public Integer iTotalRecords;
        public Integer iTotalDisplayRecords;
        public SObject[] aaData;
        Response(Integer echo, Integer total, SObject[] sobs) {
            this.sEcho = echo;
            this.iTotalRecords = total;
            this.iTotalDisplayRecords = total;
            this.aaData = sobs;
        }
    }
 	//Pass Json  Data To server
    // DataTable passes JSON definition of what server should do
    //i have added a new chandge
    private class Params {
     
        Map<String, Object> m = new Map<String, Object>();
         
        Integer echo;
        Integer start;
        Integer length;
        String[] columns;
        Integer[] sortColumns;
        String[] sortDirections;
         
        Params(List<Map<String, Object>> request) {
            for (Map<String, Object> r : request) {
                m.put((String) r.get('name'), r.get('value'));
            }
            echo = integer('sEcho');
            start = integer('iDisplayStart');
            length = integer('iDisplayLength');
            columns = stringArray('mDataProp');
            sortColumns = integerArray('iSortCol');
            sortDirections = stringArray('sSortDir');
        }
         
        String[] stringArray(String prefix) {
            String[] strings = new String[] {};
            for (Object o : array(prefix)) {
                strings.add(o != null ? esc(String.valueOf(o)) :null);
            }
            return strings;
        }
         
        Integer[] integerArray(String prefix) {
            Integer[] integers = new Integer[] {};
            for (Object o : array(prefix)) {
                integers.add(o != null ? Integer.valueOf(o) : null);
            }
            return integers;
        }
 
        Object[] array(String prefix) {
            Object[] objects = new Object[] {};
            for (Integer i = 0; true; i++) {
                Object o = m.get(prefix + '_' + i);
                if (o != null) {
                    objects.add(o);
                } else {
                    break;
                }
            }
            return objects;
        }
         
        Integer integer(String name) {
           Object o = m.get(name);
           if (o instanceof Decimal) {
               return ((Decimal) o).intValue();
           } else if (o instanceof Integer) {
               return (Integer) o;
           } else {
               return null;
           }
        }
         
        // Guard against SOQL injection
        String esc(String s) {
            return s != null ? String.escapeSingleQuotes(s) : null;
        }
    }
     
    @RemoteAction
    global static Response contacts(List<Map<String, Object>> request) {
     
        Params p = new Params(request);
 
        String soql = ''
                + ' select ' + String.join(p.columns, ', ')
                + ' from Contact'
                + ' order by ' + String.join(orderBys(p), ', ')
                + ' limit :length'
                + ' offset :start'
                ;
        System.debug('>>> soql=' + soql);
 
        Integer start = p.start;
        Integer length = p.length;
        return new Response(
                p.echo,
                [select Count() from Contact],
                Database.query(soql)
                );
    }
     
    private static String[] orderBys(Params p) {
        Map<String, String> soqlDirections = new Map<String, String>{
                'asc' => 'asc nulls last',
                'desc' => 'desc nulls first'
                };
        String[] orderBys = new String[] {};
        Integer min = Math.min(p.sortColumns.size(), p.sortDirections.size());
        for (Integer i = 0; i < min; i++) {
            orderBys.add(''
                    + p.columns[p.sortColumns[i]]
                    + ' '                    
                    + soqlDirections.get(p.sortDirections[i])
                    );
        }
        return orderBys;
    }
}