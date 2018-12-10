package org.osm.query.rdf.blazegraph;

import static org.hamcrest.Matchers.both;
import static org.wikidata.query.rdf.test.Matchers.assertResult;
import static org.wikidata.query.rdf.test.Matchers.binds;

import org.junit.Test;
import org.openrdf.model.impl.URIImpl;
import org.openrdf.query.TupleQueryResult;
import org.osm.query.rdf.common.uri.OSM;
import org.wikidata.query.rdf.common.uri.Ontology;
import org.wikidata.query.rdf.common.uri.SKOS;
import org.wikidata.query.rdf.common.uri.SchemaDotOrg;

public class OsmPrefixesUnitTest extends OsmBlazegraphTestBase {

    @Test
    public void testOsmPrefixes() {
        add("ontology:dummy", "ontology:dummy", "osmnode:123");
        TupleQueryResult res = query("SELECT * WHERE { wikibase:dummy ?x ?y }");
        assertResult(res, both(
                             binds("x", new URIImpl(Ontology.NAMESPACE + "dummy"))
                          ).and(
                             binds("y", new URIImpl(OSM.NODE + "123"))
                    ));

        TupleQueryResult res2 = query("SELECT * WHERE { ?x ?y osmnode:123 }");
        assertResult(res2, binds("x", new URIImpl(Ontology.NAMESPACE + "dummy")));
    }

    @Test
    public void testPrefixesRFDSandSchema() {
        add("osmway:456", SchemaDotOrg.ABOUT, SKOS.ALT_LABEL);
        TupleQueryResult res = query("SELECT * WHERE { ?x schema:about skos:altLabel }");
        assertResult(res, binds("x", new URIImpl(OSM.WAY + "456")));
    }

}
