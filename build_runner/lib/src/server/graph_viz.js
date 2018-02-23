window.$build = {}
window.$build.focusNode = function (scope) {
    return function (assetId) {
        var edges = [];
        var scope = window.$build;
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
        var primaryNode = null;
        for (var i in scope.assetGraph.nodes) {
            var node = scope.assetGraph.nodes[i];
            if (referencedNodes.has(node.id)) {
                nodes.push(node);
            }
            if (node.id == assetId) {
                primaryNode = node;
            }
        }
        var data = {
            edges: edges,
            nodes: nodes
        };
        scope.network.setData(data);

        if (primaryNode) {
            var info = primaryNode.info;
            scope.detailsContainer.innerHTML =
                '<strong>ID:</strong> ' + primaryNode.id + '<br />' +
                '<strong>Generated:</strong>' + info.isGenerated + '<br />' +
                '<strong>Hidden:</strong>' + info.hidden + '<br />' +
                '<strong>State:</strong>' + info.state + '<br />' +
                '<strong>Was Output:</strong>' + info.wasOutput + '<br />' +
                '<strong>Phase:</strong>' + info.phaseNumber + '<br />' +
                '<strong>Globs:</strong>' + info.globs + '<br />';
        }
        return null;
    }
}(window.$build);
window.$build.initializeGraph = function (scope) {
    scope.options = {
        layout: {
            hierarchical: { enabled: true }
        },
        physics: { enabled: true },
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
    scope.detailsContainer = document.getElementById('details');
    var searchbox = document.getElementById('searchbox');
    scope.searchbox = searchbox;
    scope.searchform = document.getElementById('searchform');
    searchform.addEventListener('submit', function (event) {
        event.preventDefault();
        var scope = window.$build;
        scope.focusNode(scope.searchbox.value);
        return null;
    });
    scope.network = new vis.Network(
        scope.graphContainer, { nodes: [], edges: [] }, scope.options);
    scope.network.on('doubleClick', function (event) {
        var scope = window.$build;
        if (event.nodes.length >= 1) {
            var nodeId = event.nodes[0];
            scope.focusNode(nodeId);
            return null;
        }
    });

    return function (data) {
        scope.assetGraph = data;
        console.log(
            'Got data:' + scope.assetGraph, ' with options: ' + scope.options);
    };
}(window.$build);
