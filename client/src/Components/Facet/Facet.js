import React from 'react';
import './Facet.css';
import _ from 'lodash';

class FacetEntry extends React.Component {
  render() {
    return <div className="FacetEntry">
      <label>
        <input type="checkbox" value={this.props.selected} onClick={this.props.onClick} />
        {this.props.name}
      </label>
    </div>
  }
}

class Facet extends React.Component {
  render() {
    let andFunction = _.partial(this.props.andFunction, this.props.name);
    let andOrCandidate = _.includes(this.props.andAbleFacets, this.props.name);
    let andDom;
    if (andOrCandidate) {
      let isAnding = _.includes(this.props.andFacets, this.props.name);
      if (isAnding) {
        andDom = <span className="andor" onClick={andFunction}>match some</span>
      } else {
        andDom = <span className="andor" onClick={andFunction}>match all</span>
      }
    }

    return <div className="Facet noselect">
      <div className="FacetName">{this.props.name} {andDom}</div>
      {_.keys(this.props.values).map((value, key) => {
        let toggleFunction = _.partial(this.props.toggleFunction, value);
        return <FacetEntry key={key}
                           name={value}
                           onClick={toggleFunction}
                           selected={this.props.values[value]}>
               </FacetEntry>
      })}
    </div>
  }
}

Facet.propTypes = {
  id: React.PropTypes.number,
  name: React.PropTypes.string,
  values: React.PropTypes.object
}

export default Facet;
