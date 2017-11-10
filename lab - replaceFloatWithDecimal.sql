
--REVIEW TODO items

IF NOT EXISTS(select 1 from sys.objects where name = 'Drop_and_Store_Table_Objects')
BEGIN
	THROW 51000, 'Drop_and_Store_Table_Objects stored procedure does not exist.', 1;
	SET NOEXEC ON
END


BEGIN TRY 
DROP TABLE #Triggers_to_Drop_and_Recreate;
END TRY
BEGIN CATCH
END CATCH 

CREATE TABLE #Triggers_to_Drop_and_Recreate
(	id int not null identity (1,1) primary key
,	object_name sysname null
,	object_id int not null
,	drop_tsql	nvarchar(max) null
,	create_tsql nvarchar(max) null
)


BEGIN TRY 
DROP TABLE ##Drop_and_Recreate_Objects;
END TRY
BEGIN CATCH
END CATCH 

CREATE TABLE ##Drop_and_Recreate_Objects (	table_object_id int not null PRIMARY KEY ) 


--Example of how to add a table to get its DFs, TRs and CKs recreated.
--TODO: Uncomment out the tables that need to be converted.

--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[abr_bank_account]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[abr_bank_rec]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[abr_bank_rec_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[abr_bank_rec_sequence]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[abr_check_reg_adj]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[apbalance]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[apinvoicehdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[apinvoicetrans]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[appayments]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[ardeposits]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[arinvoicehdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[arinvoicetrans]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[asset_cost_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[assets]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[assets_improvements]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[bidhdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[biditem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[biditem_custom_fields]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[categories]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[clippership_return_tq]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[contacts]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[contacts_xref]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[customer_office_xref]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[customers]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltick_void]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickhdr_addl_fields]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_addl_fields]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_addl_fields_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_custom_fields]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_dump_site]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_meters]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_ret_auth]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_route_service]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_route_service_seq_num]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_ship_from]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickitem_ship_instruct]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[delticksubhdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[delticksubhdr2]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[estimate_serials]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[estimatehdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[estimatelines]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[estimatelines_return_info]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[eventhdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[eventitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[exchangecounts]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[ext_descr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[ext_notes]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[ext_specs]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fastdt]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[fmv]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[grid_office_xref]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[gridhdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[hmced_contract_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[interoffice]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[inv_add_log]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[inven_custom_fields]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[inven_notes]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[inven_remarks]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[inventory]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[invoice_export_history]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[inventory_last_change]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[invoicehdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[invoiceitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[invoiceitem_meters]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[itype]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[job]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[jobtypelist]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[kititem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[lock]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[misc_chg]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[multiprice]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[poalloc]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[poallocrecv]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[podist]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[podist_clearing]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[podist_je]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[podist_receipts_details]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[podisthdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[podisthdr_clearing]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[pohdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[poitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[prevent]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[regdata]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[register]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[reorder]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[repairhistory]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[repairpreferences]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[sales_person]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[subcategories]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[taxcode]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_addresses]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_afe_information]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_customer_charge_checklist]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_del_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_deltick_comments]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_disposal_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_disposal_locations]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_dump_activity_codes]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_dump_service_pricing]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_dump_work_order]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_dump_work_order_lines]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_field_service_entry]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_field_service_maint_entry]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_fifo_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_fifo_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_fifo_valuation]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_interim_meter]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_inv_gljrnl]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_inv_loc_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_inv_loc_summary]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_inv_locations]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_invc_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_inventory_geolocation]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_job_activity]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_job_activity_consumables]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_job_activity_equipment]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_job_activity_labor]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_log_deltickitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_man_burden]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_mileage_lookup]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_multi_level_approval_log]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_custom_fields]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_item]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_item_prefix]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_load]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_load_order]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_entry_truck_helper]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_order_logbook_item]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_pl_relations]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_pl_setup]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_prelien_data]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_prelien_requests]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_price_lookup]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_print_config_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_print_config_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_prorate]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_qlcmm_action_log]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_qlcmm_alerts]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_qlcmm_dticket_geofence_xref]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_qlcmm_equipment_location]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_qlcmm_geofences]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_qlcmm_terminals]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_ra_add_item]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_ra_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_ra_item]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_readings]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_rental_request_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_rental_requests]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_reorder_rules]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_reorder_vendors]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_repair_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_repair_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_routesmith_log]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_rwo_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_start_stop]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_tax_brkdwn_headers]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_tax_brkdwn_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_tax_calc_headers]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_tax_calc_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_ticket_totals]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_us_1099item]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_vendor_bid_branch_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_vendor_bid_branch_items_archive]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_work_order_types]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbl_zones]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbladdon_links]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblapproved_dist_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblapproved_dist_line]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblapproved_gljrnl]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblassoc_damages]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblassociated_tires]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblcommission_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblcomponent_list]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblcontact_notes]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblcost_codes_ticket]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblcreditdetails]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblcurrency_rate]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbldoc_links]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbldown_days]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbldps_custruleitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbldps_invruleshdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbldps_invrulesitem]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblequip_request_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblequip_request_line]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblfleet_shipping_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblfleet_shipping_instruct]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblgl_balance_sheet_layout]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinspection_header]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinspection_tires]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinspection_wear_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinsurance]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinv_wash_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinv_wash_info]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinvcline_billinfo]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblinvctaxadjust]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbllanded_cost_rules]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbllanded_cost_rules_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbllog_event]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblmarket_type_list]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblmas_invoices]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblmas_recv_ctr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblmeter_readings]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblowner_share]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblp21_location_translation]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblparts_hours]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblpo_add_costs]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblpo_add_costs_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblpo_currency_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblprevent_maint_parts]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblprevent_maint_request]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblpros_prospectfor]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblpros_reason_codes]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblpros_status]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblrating_group]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblrating_group_member]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblrating_keys]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblrating_values]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblre_rent_hdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblre_rent_line]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblre_rent_line_detail]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblservice_chklist]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblservice_labor]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblservice_requests]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblservice_techs]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblservice_timetasks]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblsilent_return_set_items]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbltax_authority]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbltoolcheck]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbltrans_po_link]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbluse_snapshot]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tbluse_snapshot_item]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblwarranty_info]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[tblwarranty_labels]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[terms]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[timesheet]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[totalonorder]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[transnum]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[unithistory]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[uomconversions]'))
insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[usage]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[usagehours]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[deltickhdr]'))
--insert into ##Drop_and_Recreate_Objects (table_object_id) select (OBJECT_ID('[dbo].[invoicehdr]'))
--GO

exec dbo.Drop_and_Store_Table_Objects   @testingMode = 0, @AuditingMode = 0
--Here we need to manually fix any values that will created duplicate PK's when we convert from Float to Decimal.
--exec dbo.Fix_Duplicate_PK_Floats		@testingMode = 0, @AuditingMode = 1 --Still a Work in Progress
exec dbo.Alter_Floats_to_Decimal		@testingMode = 0, @AuditingMode = 0
exec dbo.Recreate_Stored_Table_Objects  @testingMode = 0, @AuditingMode = 0



PRINT N'Refreshing views.';

DECLARE @DropCreateTSQL nvarchar(4000) 
DECLARE DropCreateDefaults CURSOR FAST_FORWARD 
     FOR 
	select DropCreateTSQL = 'exec sp_refreshview  N''' +s.name + '.' + o.name + ''''
	from  sys.views o 
	inner join sys.schemas s on o.schema_id = s.schema_id 
	inner join sys.sql_modules m on m.object_id = o.object_id 
	where o.type_desc = 'view'
	and m.definition not like '%schemabinding%'
OPEN DropCreateDefaults
FETCH NEXT FROM DropCreateDefaults INTO @DropCreateTSQL
WHILE @@FETCH_STATUS = 0
BEGIN
	print @DropCreateTSQL;
	exec sp_executesql @DropCreateTSQL;
	FETCH NEXT FROM DropCreateDefaults INTO @DropCreateTSQL
END
CLOSE DropCreateDefaults;
DEALLOCATE DropCreateDefaults;

PRINT N'Update complete.';

