import supabase from '../db';  // Adjust the path if needed

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { employee_name } = req.body;

        // Validate the employee_name
        if (!employee_name || employee_name.trim() === '') {
            return res.status(400).json({ error: 'Employee name is required.' });
        }

        // Start transaction
        try {
            // Insert new employee into the 'employees' table
            const { data: employeeData,error: employeeError } = await supabase
                .from('employees')
                .insert([{ employee_name: employee_name.trim() }])
                .select()
                .single();

            if (employeeError) {
                throw new Error(employeeError.message);
            }

            // Insert into the 'employee_offices' table with office_id as 1 (default)
            const { data: employeeOfficeData,error: officeError } = await supabase
                .from('employee_offices')
                .insert([
                    {
                        employee_id: employeeData.employee_id,
                        office_id: 1, // Default office_id is 1
                    },
                ]);

            if (officeError) {
                throw new Error(officeError.message);
            }

            // Success response
            return res.status(201).json({
                message: 'Employee created successfully',
                employee: employeeData,
                employee_office: employeeOfficeData,
            });
        } catch (error) {
            return res.status(500).json({ error: error.message });
        }
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ error: `Method ${req.method} not allowed` });
    }
}
