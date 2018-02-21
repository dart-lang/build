window.$build = {}
window.$build.initializeGraph = function (scope) {
    scope.options = {
        layout: {
            hierarchical: { enabled: false }
        },
        physics: { enabled: false },
        configure: {
            showButton: false
        },
        edges: {
            arrows: {
                to: {
                    enabled: true
                }
            }
        }
    };
    scope.graphContainer = document.getElementById('graph');
    var searchbox = document.getElementById('searchbox');
    scope.searchbox = searchbox;
    scope.searchform = document.getElementById('searchform');
    searchform.addEventListener('submit', function (event) {
        var edges = [];
        var scope = window.$build;
        var assetId = scope.searchbox.value;
        var referencedNodes = new Set([assetId]);
        for (var i in scope.assetGraph.edges) {
            var edge = scope.assetGraph.edges[i];
            if (edge.from == assetId || edge.to == assetId) {
                edges.push(edge);
                referencedNodes.add(edge.from);
                referencedNodes.add(edge.to);
            }
        }
        var nodes = [];
        for (var i in scope.assetGraph.nodes) {
            var node = scope.assetGraph.nodes[i];
            if (referencedNodes.has(node.id)) {
                nodes.push(node);
            }
        }
        var data = {
            edges: edges,
            nodes: nodes
        };
        new vis.Network(scope.graphContainer, data, scope.options);
        event.preventDefault();
        return null;
    });

    return function (data) {
        scope.assetGraph = data;
        console.log(
            'Got data:' + scope.assetGraph, ' with options: ' + scope.options);
    };
}(window.$build);
