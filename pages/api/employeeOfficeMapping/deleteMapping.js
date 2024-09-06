// employeeOfficeMapping/deleteMapping.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'DELETE') {
        const { employee_id } = req.query;

        // Delete the mapping
        const { data,error } = await supabase
            .from('employee_office_mapping')
            .delete()
            .eq('employee_id',employee_id);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Mapping deleted successfully',data });
    } else {
        res.setHeader('Allow',['DELETE']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
