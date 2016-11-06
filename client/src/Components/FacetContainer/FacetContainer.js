import React from 'react';
import './FacetContainer.css';
import Facet from '../Facet/Facet';
import _ from 'lodash';

class FacetContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      facets: {}
    };
  }

  toggleAndFacet(facetName, e) {
    let the_state = _.clone(this.props);
    if (_.includes(the_state.andFacets, facetName)) {
      the_state.andFacets = _.remove(the_state.andFacets, facetName);
    } else {
      the_state.andFacets.push(facetName);
    }

    this.props.onAndFacetChange(the_state.andFacets);
  }

  toggleFacetEntry(facetName, facetEntryValue, e) {
    let the_state = _.clone(this.props);
    let selected = the_state.facets[facetName][facetEntryValue];
    the_state.facets[facetName][facetEntryValue] = !selected;

    let selectedFacets = _.reduce(_.map(the_state.facets, (facetEntry, facetName) => {
      let selectedFacet = {}

      selectedFacet[facetName] = _.compact(_.map(facetEntry, (facetEntryValue, facetEntryKey) => {
        if (facetEntryValue) return facetEntryKey;
      }));

      return selectedFacet;
    }), (result, value) => _.merge(result, value), {});

    the_state.selectedFacets = selectedFacets;

    this.props.onFacetChange(the_state.selectedFacets);
  }

  render() {
    return <div className="FacetContainer noselect">
      {_.map(_.keys(this.props.facets), (facetKey, index) => {
          let toggleFunction = _.partial(this.toggleFacetEntry, facetKey);
          let andFunction = _.partial(this.toggleAndFacet, facetKey);
          return <Facet key={index}
                        name={facetKey}
                        values={this.props.facets[facetKey]}
                        andFunction={andFunction.bind(this)}
                        andFacets={this.props.andFacets}
                        andAbleFacets={this.props.andAbleFacets}
                        toggleFunction={toggleFunction.bind(this)}>
                 </Facet>
      })}
    </div>
  }
}

FacetContainer.propTypes = {
  facets: React.PropTypes.object,
  onFacetChange: React.PropTypes.func
}

export default FacetContainer;
