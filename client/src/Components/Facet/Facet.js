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

  getSortByFunction(name) {
    switch(name) {
    case "size":
      return function(size){
        switch (size) {
        case "S":
          return 0;
        case "M":
          return 1;
        case "L":
          return 2;
        case "XL":
          return 3;
        default:
          return 4;
        };
      };

    case "age":
      return function(age){
        switch (age) {
        case "Young":
          return 0;
        case "Adult":
          return 1;
        case "Senior":
          return 2;
        default:
          return 4;
        }
      };

    default:
      return _.identity;
      break;
    }
  }

  getFormattedKey(name, value) {
    switch(name) {
    case "options":
      switch (value) {
      case "hasShots":
        return "has Shots";
      case "noCats":
        return "no Cats";
      case "noDogs":
        return "no Dogs";
      case "specialNeeds":
        return "special Needs";
      default:
        return value;
      }
    default:
      return value;
    };
  };

  getSortedKeys(name, values) {
    let sortBy = this.getSortByFunction(name);
    return _.sortBy(values, sortBy);
  }

  render() {
    let andFunction = _.partial(this.props.andFunction, this.props.name);
    let andOrCandidate = _.includes(this.props.andAbleFacets, this.props.name);
    let andDom;
    if (andOrCandidate) {
      let isAnding = _.includes(this.props.andFacets, this.props.name);
      if (isAnding) {
        andDom = <span className="andor" onClick={andFunction}>match some</span>;
      } else {
        andDom = <span className="andor" onClick={andFunction}>match all</span>;
      }
    }

    let formattedKeys = _.map(_.keys(this.props.values), _.partial(this.getFormattedKey, this.props.name));
    let sortedKeys = this.getSortedKeys(this.props.name, formattedKeys);

    let toggleName = "facet-toggle-" + this.props.name;

    return <div className="Facet noselect">
      <label htmlFor={toggleName}>
        <div className="FacetName">
          {this.props.name}
          {andDom}
        </div>
      </label>
      <input type="checkbox" id={toggleName}/>
      {sortedKeys.map((value, key) => {
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
