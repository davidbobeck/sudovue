// Vue.config.devtools = true;

// Vue.component('braggin-thumb', {
//   // data: function () {
//   //   return {
//   //     photo: {}
//   //   }
//   // },
//   props: ['photo'],
//   template: `<p class="foo bar">{{photo.title}}</p>`
// })

const vue = new Vue ({
    el: '#vue-root',
    data: {
        cells: [],
        brush_color: 0,
        hovering: false,
        hovering_text: 'dude',
        displayMode: 'colors'
    },
    mounted() {
      this.getCells();
    },
    updated() {
    },
    methods: {
        getCells: function() {
            $.ajax({
                url: '/cells',
                type: 'GET',
                dataType: 'json',
                success: function (result) {
                    vue.cells = result;
                    // alert(JSON.stringify(vue.cells));
                    // vue.gatheringCells = false;
                },
                error: function (result) {
                    alert('error getting the cell data');
                }
            });
        },
        exportCells: function() {
            let data = {cells: vue.cells};
            $.ajax({
                url: '/export',
                type: 'POST',
                data: JSON.stringify(data),
                contentType: 'application/json',
                dataType: 'json',
                success: function (result) {
                    //alert(JSON.stringify(result));
                    let jsonBlob = new Blob([JSON.stringify(result)], { type: 'application/json;charset=utf-8' });
                    let link = window.URL.createObjectURL(jsonBlob);
                    window.location = link;
                    // window.open(link, '_blank');
                    // window.open(link);
                },
                error: function (result) {
                    alert('error exporting the puzzle');
                }
            });
        },
        solveCells: function() {
            let data = {cells: vue.cells};
            $.ajax({
                url: '/solve',
                type: 'POST',
                data: JSON.stringify(data),
                contentType: 'application/json',
                dataType: 'json',
                success: function (result) {
                    vue.cells = result;
                    // alert(JSON.stringify(vue.cells));
                    // vue.gatheringCells = false;
                },
                error: function (result) {
                    alert('error solving the puzzle');
                }
            });
        },
        onClickCell: function(cell) {
            // const cell = $(event.target);
            // alert('cell clicked ' + cell.id);
            // cell.orig = cell.color;
            cell.color = vue.brush_color;
        },
        onClickBrush: function(color) {
            // alert('brush clicked: ' + color);
            vue.brush_color = color;
        },
        onClickClear: function() {
            vue.cells.forEach(function(cell){
                cell.color = 0;
            });
        },
        onClickSolve: function() {
            // alert(JSON.stringify(vue.cells));
            vue.solveCells();
        },
        onClickReset: function() {
            // alert(JSON.stringify(vue.cells));
            vue.getCells();
        },
        onClickExport: function() {
            vue.exportCells();
        },
        onMouseEnter: function(cell) {
            vue.hovering = true;
            vue.hovering_text = cell.id.toString() + ': ' + cell.suspects;
        },
        onMouseLeave: function(cell) {
            vue.hovering = false;
            // vue.hovering_text = ''
        },
        colorFromNumber: function (num) {
            if (vue == undefined) { return; }
            if (vue.displayColors) {
                switch (num) {
                    case 0: return 'silver';
                    case 1: return 'crimson';
                    case 2: return 'orange';
                    case 3: return 'yellow';
                    case 4: return 'lightgreen';
                    case 5: return 'green';
                    case 6: return 'lightblue';
                    case 7: return 'royalblue';
                    case 8: return 'hotpink';
                    case 9: return 'RebeccaPurple';
                    default: return 'black';
                }
            } else {
                return "transparent";
            }
        },
        labelFromNumber: function(num) {
            if (num === 0) {
              return '';
            } else {
              return num;
            }
        },
        displayAsBall: function(cell) {
            return (cell.color > 0);
        }
    },
    computed: {
        displayDigits: function () {
            return vue.displayMode === 'digits' || vue.displayMode === 'both'
        },
        displayColors: function () {
            return vue.displayMode === 'colors' || vue.displayMode === 'both'
        }
    }
});
