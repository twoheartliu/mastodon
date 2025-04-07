import { connect } from 'react-redux';

import ColumnsArea from '../components/columns_area';

const mapStateToProps = (state, { singleColumn, layoutType }) => ({
  columns: state.getIn(['settings', 'columns']),
  isModalOpen: state.get('modal').size > 0,
  singleColumn,
  layoutType,
});

export default connect(mapStateToProps)(ColumnsArea);
